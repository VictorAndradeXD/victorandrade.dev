# Versão de Windows (packaging/windows): a mesma app de produção, rodando na
# máquina de uma pessoa só, em http://localhost, sem proxy na frente.
require_relative "production"

DESKTOP_PORT = ENV.fetch("PORT", 3210).to_i

Rails.application.configure do
  # Não há TLS em localhost. Com o force_ssl de produção, o primeiro acesso
  # seria redirecionado para um https://localhost que não existe.
  config.assume_ssl = false
  config.force_ssl  = false

  config.hosts = [ "localhost", "127.0.0.1" ]

  # Não há servidor de e-mail. A troca de senha do primeiro acesso usa o link
  # que o lançador abre direto no navegador; o "esqueci a senha" grava o e-mail
  # em tmp/mails em vez de enviar.
  config.action_mailer.delivery_method = :file
  config.action_mailer.default_url_options = { host: "localhost", port: DESKTOP_PORT }
end
