# Bancos de teste antes do servidor existir: o do bin/share (testadores pelo
# túnel) e o da versão de Windows (packaging/windows). Os dois nascem para ser
# levados ao servidor depois, então nenhum recebe o admin@app.test do seed: um
# usuário de mentira, com senha que ninguém sabe, iria junto no dump.
module Prototipo
  # IDs do Windows começam em 1 bilhão. O banco do bin/share vai para o
  # servidor inteiro, com IDs baixos; o do Windows é somado a ele depois, e com
  # faixas que não se cruzam o pg_restore só acrescenta linhas — sem remapear
  # chave nenhuma. O lado baixo nunca chega a 1 bilhão de linhas.
  ID_OFFSET_PADRAO = 1_000_000_000

  module_function

  # Cria o banco se faltar e leva o schema à versão atual. Devolve true quando
  # o banco acabou de nascer.
  def preparar_schema!
    # Em desenvolvimento (bin/share) o db:migrate regravaria o db/schema.rb com
    # a formatação do Postgres da vez — sujeira no git a cada compartilhamento.
    ActiveRecord.dump_schema_after_migration = false
    Rake::Task["db:create"].invoke

    if ActiveRecord::Base.lease_connection.data_source_exists?("schema_migrations")
      Rake::Task["db:migrate"].invoke
      false
    else
      Rake::Task["db:schema:load"].invoke
      true
    end
  end

  # Empurra toda sequência abaixo do offset para o offset. Roda a cada início,
  # não só no primeiro: uma migration nova cria tabela com sequência em 1, e
  # ela também precisa ir para a faixa alta antes de receber a primeira linha.
  def deslocar_ids!(offset)
    conn = ActiveRecord::Base.lease_connection

    conn.select_rows(<<~SQL).each do |schema, sequence, last_value|
      SELECT schemaname, sequencename, last_value FROM pg_sequences WHERE schemaname = 'public'
    SQL
      next if last_value && last_value.to_i >= offset

      conn.execute("SELECT setval(#{conn.quote("#{schema}.#{sequence}")}::regclass, #{offset.to_i}, false)")
    end
  end

  def carregar_tabelas_fiscais!
    load Rails.root.join("db/seeds/tax_tables.rb")
  end
end

namespace :prototipo do
  desc "Cria ou atualiza o banco do bin/share, sem o usuário do seed"
  task preparar: "db:load_config" do
    Prototipo.preparar_schema!
    Prototipo.carregar_tabelas_fiscais!
  end
end

namespace :desktop do
  # Chamada pelo lançador do Windows a cada início, antes de subir o Puma.
  # Entradas, pelo ambiente:
  #   DENFIS_PRIMEIRO_EMAIL     e-mail da conta, informado no instalador
  #   DENFIS_PRIMEIRO_CONTABIL  "1" para liberar também o módulo contábil
  #   DENFIS_SENHA_PENDENTE     arquivo que marca a senha ainda não definida
  #   DENFIS_ID_OFFSET          início da faixa de IDs desta instalação
  # Saída: uma linha LINK_SENHA=<caminho> enquanto a pessoa não tiver definido
  # a própria senha (o lançador abre esse link no navegador), ou SEM_CONTA se
  # não houver conta nenhuma.
  desc "Prepara o banco da versão de Windows (uso interno do lançador)"
  task preparar: "db:load_config" do
    offset = Integer(ENV.fetch("DENFIS_ID_OFFSET", Prototipo::ID_OFFSET_PADRAO))
    marcador = ENV["DENFIS_SENHA_PENDENTE"].presence&.then { |path| Pathname(path) }

    Prototipo.preparar_schema!
    # Antes de qualquer insert: os registros do seed também nascem na faixa alta.
    Prototipo.deslocar_ids!(offset)

    Rake::Task["environment"].invoke

    if User.none? && (email = ENV["DENFIS_PRIMEIRO_EMAIL"].presence)
      # O seeds.rb é o mesmo do servidor: cria a conta com as tags e a Carteira
      # padrão, e as tabelas fiscais. A senha sorteada nunca é mostrada — a
      # pessoa define a dela pelo link abaixo, na tela de troca de senha.
      ENV["DENFIS_SEED_EMAIL"]    = email
      ENV["DENFIS_SEED_PASSWORD"] = SecureRandom.base58(32)
      load Rails.root.join("db/seeds.rb")

      user = User.find_by!(email_address: email.strip.downcase)
      user.update!(accounting_access: true) if ENV["DENFIS_PRIMEIRO_CONTABIL"] == "1"

      marcador&.write(Digest::SHA256.hexdigest(user.password_digest))
    else
      # Em toda atualização: traz números novos das tabelas fiscais.
      Prototipo.carregar_tabelas_fiscais!
    end

    # Sem conta e sem e-mail do instalador, ninguém conseguiria entrar.
    puts "SEM_CONTA" if User.none?

    # O token de troca de senha vale 15 minutos. Enquanto o digest for o da
    # senha sorteada, cada início gera um link novo — quem fechou a janela sem
    # definir a senha não fica trancado do lado de fora.
    if marcador&.exist?
      user = User.order(:id).first
      if user && Digest::SHA256.hexdigest(user.password_digest) == marcador.read.strip
        puts "LINK_SENHA=#{Rails.application.routes.url_helpers.edit_password_path(user.password_reset_token)}"
      else
        marcador.delete
      end
    end
  end
end
