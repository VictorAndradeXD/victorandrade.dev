# Cria o primeiro usuário e um conjunto inicial de tags.
# Idempotente: rodar de novo não duplica nada.
#
#   DENFIS_SEED_EMAIL=voce@exemplo.com DENFIS_SEED_PASSWORD=... bin/rails db:seed
#
# Sem DENFIS_SEED_PASSWORD, uma senha aleatória é gerada e impressa uma vez.

# Endereço de desenvolvimento. O domínio `.test` é reservado pela RFC 2606 e não
# pode ser registrado por ninguém: um e-mail de recuperação de senha disparado
# por engano não tem como chegar na caixa de um estranho. Por isso não é .com.
# Quando o endereço real for definido, troque aqui ou passe DENFIS_SEED_EMAIL.
email = ENV.fetch("DENFIS_SEED_EMAIL", "admin@denfis.test")
password = ENV["DENFIS_SEED_PASSWORD"].presence || SecureRandom.alphanumeric(16)

user = User.find_by(email_address: email)

if user
  puts "Usuário #{email} já existe — senha mantida."
else
  user = User.create!(email_address: email, password: password, password_confirmation: password)
  puts "Usuário criado: #{email}"
  puts "Senha: #{password}" unless ENV["DENFIS_SEED_PASSWORD"].present?
end

DEFAULT_TAGS = {
  "Alimentação" => "#f59e0b",
  "Moradia"     => "#818cf8",
  "Transporte"  => "#38bdf8",
  "Saúde"       => "#34d399",
  "Lazer"       => "#f472b6",
  "Salário"     => "#22c55e"
}.freeze

DEFAULT_TAGS.each do |name, color|
  user.tags.find_or_create_by!(name: name) { |tag| tag.color = color }
end

user.accounts.find_or_create_by!(name: "Carteira") do |account|
  account.kind = "wallet"
  account.initial_balance = 0
end

puts "#{user.tags.count} tag(s) e #{user.accounts.count} conta(s) prontas."
