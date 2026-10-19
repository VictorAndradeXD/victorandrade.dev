# Teste de fumaça de uma instalação ligada: percorre o primeiro acesso como a
# pessoa faria — criar a senha pelo link, entrar, abrir os módulos.
#
#   ruby teste_fumaca.rb <pasta de dados> [porta]
#
# Roda no CI do Windows logo depois do instalador, e no Linux contra o
# lançador, para conferir o fluxo antes de gastar um build.
require "net/http"
require "uri"

DADOS = ARGV.fetch(0)
PORTA = Integer(ARGV[1] || 3210)
SENHA = "senha-do-teste-de-fumaca"
# O allow_browser :modern do app recusa quem não se apresenta como navegador.
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"

@cookies = {}

def pedir(metodo, caminho, form = nil)
  req = (metodo == :get ? Net::HTTP::Get : Net::HTTP::Post).new(caminho)
  req["User-Agent"] = UA
  req["Cookie"] = @cookies.map { |k, v| "#{k}=#{v}" }.join("; ") if @cookies.any?
  req.set_form_data(form) if form

  res = Net::HTTP.start("localhost", PORTA, read_timeout: 60) { |http| http.request(req) }
  Array(res.get_fields("set-cookie")).each do |linha|
    nome, valor = linha.split(";").first.split("=", 2)
    @cookies[nome] = valor
  end
  res
end

def confere(descricao, condicao)
  abort "FALHOU: #{descricao}" unless condicao
  puts "ok  #{descricao}"
end

def csrf(res) = res.body[/name="csrf-token" content="([^"]+)"/, 1]

def destino(res) = URI(res["location"].to_s).path

log = File.read(File.join(DADOS, "log", "preparar.log"))
link = log[/^LINK_SENHA=(\S+)/, 1]
confere "o lançador gerou o link de primeiro acesso", link

res = pedir(:get, link)
confere "a tela de criar senha abre", res.code == "200" && res.body.include?("password_confirmation")

res = pedir(:post, link.delete_suffix("/edit"),
            "_method" => "patch", "authenticity_token" => csrf(res),
            "password" => SENHA, "password_confirmation" => SENHA)
confere "a senha é aceita", res.code == "302" && destino(res) == "/session/new"

email = File.read(File.join(DADOS, "primeiro-acesso.txt"), encoding: "bom|utf-8")[/^email=(.+)$/, 1].strip
res = pedir(:get, "/session/new")
res = pedir(:post, "/session", "authenticity_token" => csrf(res), "email_address" => email, "password" => SENHA)
confere "o login com a senha nova funciona", res.code == "302" && destino(res) == "/denfis"

res = pedir(:get, "/app")
confere "o ícone do app leva ao Denfis", res.code == "302" && destino(res) == "/denfis"

%w[/denfis /denfis/transactions /denfis/extrato /denfis/transactions/new /contabil].each do |caminho|
  confere "#{caminho} abre", pedir(:get, caminho).code == "200"
end

css = pedir(:get, "/denfis").body[%r{/assets/application-[^"]+\.css}]
confere "o CSS pré-compilado é servido", css && pedir(:get, css).code == "200"

puts "Tudo certo."
