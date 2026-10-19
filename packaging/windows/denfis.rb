# Lançador da versão de Windows. É o que o atalho "Denfis" abre, numa janela
# de console que fica aberta enquanto o app roda.
#
#   ruby denfis.rb           liga tudo e abre o navegador
#   ruby denfis.rb backup    grava um backup agora, na pasta de backups
#   ruby denfis.rb parar     desliga o servidor e o banco
#
# Layout da instalação, ao lado deste arquivo:
#   ruby\    o Ruby do RubyInstaller, com as gems já compiladas em app\vendor
#   pgsql\   os binários do Postgres 18 (o mesmo major do servidor)
#   app\     a aplicação Rails, com os assets pré-compilados
#
# Os dados ficam fora da pasta do programa, em %LOCALAPPDATA%\Denfis: reinstalar
# ou atualizar troca os arquivos do programa e nunca toca no banco.
#
# Também roda no Linux, para testar: as variáveis DENFIS_* no topo da classe
# apontam cada peça para outro lugar.
require "fileutils"
require "json"
require "net/http"
require "securerandom"
require "time"

class Denfis
  WINDOWS   = Gem.win_platform?
  EXE       = WINDOWS ? ".exe" : ""
  HOME      = __dir__

  WEB_PORT  = Integer(ENV.fetch("DENFIS_PORTA", 3210))
  # Porta fora do padrão: um Postgres que a pessoa já tenha instalado fica na
  # 5432, e os dois não brigam.
  PG_PORT   = Integer(ENV.fetch("DENFIS_PORTA_BANCO", 54329))
  DB_NAME   = "denfis_desktop"
  DB_USER   = "denfis"
  BACKUPS_MANTIDOS = 30

  def initialize
    @ruby    = ENV["DENFIS_RUBY"]   || File.join(HOME, "ruby", "bin", "ruby#{EXE}")
    @pg_bin  = ENV["DENFIS_PG_BIN"] || File.join(HOME, "pgsql", "bin")
    @app     = ENV["DENFIS_APP"]    || File.join(HOME, "app")
    @dados   = ENV["DENFIS_DADOS"]  || File.join(ENV.fetch("LOCALAPPDATA"), "Denfis")
    @backups = ENV["DENFIS_BACKUPS"] || File.join(pasta_documentos, "Denfis", "Backups")

    @pgdata  = File.join(@dados, "pgdata")
    @logs    = File.join(@dados, "log")
    @pidfile = File.join(@dados, "puma.pid")
    # Deixado pelo "parar" (o atalho Desligar), para a janela aberta saber que
    # o servidor saiu porque pediram, e não por erro.
    @pedido_de_parada = File.join(@dados, "parando")
  end

  def iniciar(abrir_navegador: true)
    if servidor_no_ar?
      say "O Denfis já está ligado. Abrindo o navegador..."
      abrir(url("/app")) if abrir_navegador
      return
    end

    say "Ligando o Denfis. Na primeira vez leva um minuto."
    preparar_pastas
    FileUtils.rm_f(@pedido_de_parada)
    iniciar_banco
    backup_automatico
    link_senha = preparar_aplicacao
    puma = iniciar_servidor

    if link_senha
      say ""
      say "Primeiro acesso: o navegador vai abrir na tela para você criar a sua senha."
      say "(O link vale 15 minutos. Se passar, feche esta janela e abra o Denfis de novo.)"
    end
    abrir(url(link_senha || "/app")) if abrir_navegador

    say ""
    say "─" * 60
    say "  Denfis ligado em #{url('/')}"
    say ""
    say "  Deixe esta janela aberta enquanto usa (pode minimizar)."
    say "  Para desligar, feche a janela."
    say "─" * 60

    Process.wait(puma)
    if File.exist?(@pedido_de_parada)
      FileUtils.rm_f(@pedido_de_parada)
      say "", "Denfis desligado."
    elsif !@parando
      falha "O servidor parou sozinho. Detalhes em #{File.join(@logs, 'denfis.log')}"
    end
  end

  def backup
    preparar_pastas
    ja_ligado = banco_no_ar?
    iniciar_banco unless ja_ligado
    arquivo = gravar_backup
    say "Backup gravado em:"
    say "  #{arquivo}"
    say ""
    say "Para levar seus dados ao servidor, envie esse arquivo para o Victor."
  ensure
    parar_banco if ja_ligado == false
  end

  def parar
    @parando = true
    FileUtils.touch(@pedido_de_parada) if File.exist?(@pidfile)
    parar_servidor
    parar_banco
    say "Denfis desligado."
  end

  private
    # ---- banco ------------------------------------------------------------

    def iniciar_banco
      inicializar_cluster unless File.exist?(File.join(@pgdata, "PG_VERSION"))
      return if banco_no_ar?

      say "  ligando o banco..."
      log = File.join(@logs, "postgres.log")
      ok = run(pg("pg_ctl"), "start", "-D", @pgdata, "-l", log, "-w", "-t", "120", quiet: true)

      # Depois de um desligamento brusco (luz, Windows Update) sobra um
      # postmaster.pid, e se o Windows reaproveitou aquele PID o Postgres acha
      # que ainda está rodando. Sem servidor de fato no ar, o arquivo é lixo.
      unless ok
        FileUtils.rm_f(File.join(@pgdata, "postmaster.pid"))
        run(pg("pg_ctl"), "start", "-D", @pgdata, "-l", log, "-w", "-t", "120", quiet: true) or
          falha("O banco não ligou. Detalhes em #{log}")
      end
    end

    def inicializar_cluster
      say "  criando o banco de dados (só na primeira vez)..."
      FileUtils.rm_rf(@pgdata)

      pwfile = File.join(@dados, "pwfile.tmp")
      File.write(pwfile, segredos["db_password"])
      base = [ pg("initdb"), "-D", @pgdata, "-U", DB_USER, "-E", "UTF8",
               "--auth=scram-sha-256", "--pwfile=#{pwfile}" ]

      # Ordenação em português (Água junto de Abacaxi, não depois de Zebra),
      # como no servidor. Se o ICU faltar, fica a ordem por código, que é feia
      # mas não perde nada.
      ok = run(*base, "--locale=C", "--locale-provider=icu", "--icu-locale=pt-BR", quiet: true)
      unless ok
        FileUtils.rm_rf(@pgdata)
        run(*base, "--locale=C", quiet: true) or falha("Não consegui criar o banco de dados.")
      end

      # Só a própria máquina conversa com o banco, e só por TCP. Sem socket
      # Unix: no Windows ele já vem desligado, e assim o teste no Linux se
      # comporta igual.
      File.open(File.join(@pgdata, "postgresql.conf"), "a") do |conf|
        conf.puts "", "# Denfis", "listen_addresses = '127.0.0.1'", "port = #{PG_PORT}",
                  "unix_socket_directories = ''", "max_connections = 20"
      end
    ensure
      FileUtils.rm_f(pwfile) if pwfile
    end

    def banco_no_ar?
      File.exist?(File.join(@pgdata, "PG_VERSION")) &&
        run(pg("pg_ctl"), "status", "-D", @pgdata, quiet: true)
    end

    def parar_banco
      return unless banco_no_ar?

      run(pg("pg_ctl"), "stop", "-D", @pgdata, "-m", "fast", "-w", quiet: true)
    end

    def banco_existe?
      out = IO.popen(env_banco, [ pg("psql"), *conexao, "-d", "postgres", "-Atc",
                                  "select 1 from pg_database where datname = '#{DB_NAME}'" ],
                     err: File::NULL, &:read)
      out.strip == "1"
    end

    # ---- backups ----------------------------------------------------------

    # A cada início, antes das migrations: se uma atualização der errado, o
    # estado de logo antes está guardado.
    def backup_automatico
      return unless banco_existe?

      say "  guardando um backup..."
      gravar_backup
      antigos = Dir[File.join(@backups, "denfis-*.dump")].sort[0...-BACKUPS_MANTIDOS]
      FileUtils.rm_f(antigos) if antigos
    end

    def gravar_backup
      falha("Ainda não há dados para guardar.") unless banco_existe?

      FileUtils.mkdir_p(@backups)
      arquivo = File.join(@backups, "denfis-#{Time.now.strftime('%Y%m%d-%H%M%S')}.dump")
      parcial = "#{arquivo}.part"

      # Formato custom: é o que o pg_restore do servidor lê, tabela a tabela.
      run(pg("pg_dump"), *conexao, "-d", DB_NAME, "-Fc", "-f", parcial, env: env_banco) or
        falha("O backup falhou.")
      File.rename(parcial, arquivo)
      arquivo
    ensure
      FileUtils.rm_f(parcial) if parcial && File.exist?(parcial)
    end

    # ---- aplicação --------------------------------------------------------

    # Cria o banco na primeira vez, roda as migrations nas seguintes (ver
    # lib/tasks/prototipo.rake). Devolve o link de criar senha, se ainda faltar.
    def preparar_aplicacao
      say "  preparando a aplicação..."
      primeiro = ler_primeiro_acesso
      env = env_app.merge(
        "DENFIS_PRIMEIRO_EMAIL"    => primeiro["email"].to_s,
        "DENFIS_PRIMEIRO_CONTABIL" => primeiro["contabil"].to_s,
        "DENFIS_SENHA_PENDENTE"    => File.join(@dados, "senha-pendente")
      )

      saida = IO.popen(env, [ @ruby, "bin/rails", "desktop:preparar" ],
                       chdir: @app, err: [ :child, :out ], &:read)
      File.write(File.join(@logs, "preparar.log"), saida)
      falha("A preparação do banco falhou. Detalhes em #{File.join(@logs, 'preparar.log')}") unless $?.success?
      if saida.match?(/^SEM_CONTA$/)
        falha("Nenhuma conta foi configurada. Rode o instalador de novo e informe o seu e-mail.")
      end

      saida[/^LINK_SENHA=(\S+)/, 1]
    end

    def iniciar_servidor
      say "  ligando o servidor..."
      log = File.open(File.join(@logs, "denfis.log"), "a")

      # Ligado só em 127.0.0.1: ninguém da rede alcança, e o Firewall do
      # Windows nem pergunta nada.
      pid = Process.spawn(env_app, @ruby, "-S", "bundle", "exec", "puma",
                          "-C", "config/puma.rb", "-b", "tcp://127.0.0.1:#{WEB_PORT}",
                          "-e", "desktop", "--pidfile", @pidfile,
                          chdir: @app, out: log, err: log)

      # Ctrl+C na janela desliga tudo direito. Fechar a janela no X não passa
      # por aqui (o Windows encerra o processo na hora) — e tudo bem: o
      # Postgres se recupera sozinho de um desligamento brusco, pelo WAL.
      at_exit do
        @parando = true
        parar_servidor
        parar_banco
      end

      # Boot do Rails no Windows leva alguns segundos; o navegador só abre com
      # o servidor respondendo, para a pessoa não ver uma página de erro.
      120.times do
        return pid if servidor_no_ar?
        if Process.waitpid(pid, Process::WNOHANG)
          falha("O servidor não ligou. Detalhes em #{log.path}")
        end
        sleep 1
      end
      falha("O servidor demorou demais para ligar. Detalhes em #{log.path}")
    end

    def parar_servidor
      return unless File.exist?(@pidfile)

      pid = File.read(@pidfile).to_i
      Process.kill(WINDOWS ? "KILL" : "TERM", pid) if pid.positive?
    rescue Errno::ESRCH, Errno::EINVAL
      # Já tinha parado.
    ensure
      FileUtils.rm_f(@pidfile)
    end

    def servidor_no_ar?
      Net::HTTP.start("127.0.0.1", WEB_PORT, open_timeout: 1, read_timeout: 3) do |http|
        http.get("/up").is_a?(Net::HTTPSuccess)
      end
    rescue StandardError
      false
    end

    # ---- ambiente ---------------------------------------------------------

    def preparar_pastas
      [ @dados, @logs ].each { |dir| FileUtils.mkdir_p(dir) }
    end

    # Sorteados no primeiro uso e guardados só nesta máquina. Nada disto vai
    # no instalador: cada instalação tem os próprios.
    def segredos
      @segredos ||= begin
        arquivo = File.join(@dados, "segredos.json")
        if File.exist?(arquivo)
          JSON.parse(File.read(arquivo))
        else
          novos = { "db_password" => SecureRandom.alphanumeric(32), "secret_key_base" => SecureRandom.hex(64) }
          File.write("#{arquivo}.tmp", JSON.pretty_generate(novos))
          File.rename("#{arquivo}.tmp", arquivo)
          novos
        end
      end
    end

    # Gravado pelo instalador (e-mail e módulos), uma linha "chave=valor" cada.
    def ler_primeiro_acesso
      arquivo = File.join(@dados, "primeiro-acesso.txt")
      return {} unless File.exist?(arquivo)

      File.read(arquivo, encoding: "bom|utf-8").lines.filter_map do |line|
        key, value = line.strip.split("=", 2)
        [ key, value ] if key && value
      end.to_h
    end

    def conexao = [ "-h", "127.0.0.1", "-p", PG_PORT.to_s, "-U", DB_USER ]

    def env_banco = env_limpo.merge("PGPASSWORD" => segredos["db_password"])

    def env_app
      env_limpo.merge(
        "RAILS_ENV"                 => "desktop",
        "PORT"                      => WEB_PORT.to_s,
        "SECRET_KEY_BASE"           => segredos["secret_key_base"],
        "DENFIS_DATABASE_HOST"      => "127.0.0.1",
        "DENFIS_DATABASE_PORT"      => PG_PORT.to_s,
        "DENFIS_DATABASE_USER"      => DB_USER,
        "DENFIS_DATABASE_PASSWORD"  => segredos["db_password"],
        "BUNDLE_GEMFILE"            => File.join(@app, "Gemfile"),
        "RAILS_LOG_LEVEL"           => "warn"
      )
    end

    # Um Ruby ou Postgres que a pessoa já tenha instalado não pode vazar para
    # dentro do app: o PATH é montado do zero e as variáveis de gem saem.
    #
    # O spawn *soma* este hash ao ambiente herdado, então tirar uma chave do
    # hash não basta — ela precisa ir com nil para sumir do processo filho.
    def env_limpo
      env = ENV.keys.grep(/\A(RUBY|GEM_|BUNDLE_|PG)/i).to_h { |key| [ key, nil ] }

      path = [ File.dirname(@ruby), @pg_bin ]
      if WINDOWS
        path << File.join(File.dirname(@ruby), "ruby_builtin_dlls")
        root = ENV.fetch("SYSTEMROOT", 'C:\Windows')
        path += [ File.join(root, "System32"), root, File.join(root, "System32", "Wbem") ]
        path = path.map { |dir| dir.tr("/", "\\") }
      else
        path += %w[/usr/bin /bin]
      end
      # No Windows a chave pode vir como "Path"; todas as grafias recebem o valor.
      ENV.keys.grep(/\APATH\z/i).push("PATH").uniq.each { |key| env[key] = path.join(File::PATH_SEPARATOR) }
      env
    end

    def pg(binario) = File.join(@pg_bin, "#{binario}#{EXE}")

    def url(path) = "http://localhost:#{WEB_PORT}#{path}"

    # Na pasta Documentos, onde a pessoa acha sem saber o que é AppData — e
    # que o OneDrive costuma copiar para a nuvem, de graça.
    def pasta_documentos
      if WINDOWS
        require "win32/registry"
        Win32::Registry::HKEY_CURRENT_USER.open('Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders') do |reg|
          return reg["Personal"]
        end
      end
      File.join(Dir.home, "Documents")
    rescue StandardError
      File.join(Dir.home, "Documents")
    end

    def abrir(endereco)
      if WINDOWS
        # rundll32 e não `start`: o cmd trata o "=" do token como separador.
        Process.detach(Process.spawn("rundll32.exe", "url.dll,FileProtocolHandler", endereco))
      else
        Process.detach(Process.spawn("xdg-open", endereco, out: File::NULL, err: File::NULL))
      end
    end

    def run(*cmd, env: env_limpo, quiet: false)
      opts = quiet ? { out: File::NULL, err: File::NULL } : {}
      system(env, *cmd, **opts)
    end

    def say(*linhas) = $stdout.puts(*linhas)

    def falha(msg) = raise(Falha, msg)

  class Falha < StandardError; end
end

if $PROGRAM_NAME == __FILE__
  # Console do Windows em UTF-8, senão "não" vira "n├úo".
  system("chcp 65001 >NUL") if Denfis::WINDOWS
  $stdout.sync = true

  comando = ARGV.reject { |arg| arg.start_with?("--") }.first || "iniciar"
  denfis = Denfis.new

  begin
    case comando
    when "iniciar" then denfis.iniciar(abrir_navegador: !ARGV.include?("--sem-navegador"))
    when "backup"  then denfis.backup
    when "parar"   then denfis.parar
    else abort "Comando desconhecido: #{comando}"
    end
  rescue Denfis::Falha => e
    warn "", "Erro: #{e.message}"
    exitcode = 1
  rescue Interrupt
    exitcode = 0
  end

  # Aberto por atalho, o console fecharia na hora e levaria a mensagem junto.
  if Denfis::WINDOWS && $stdin.tty? && !ARGV.include?("--sem-pausa") && (exitcode || comando != "iniciar")
    $stdout.print "\nPressione Enter para fechar."
    $stdin.gets
  end
  exit(exitcode || 0)
end
