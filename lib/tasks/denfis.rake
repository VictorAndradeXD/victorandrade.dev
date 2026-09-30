namespace :denfis do
  desc "Cria acesso ao Denfis. EMAIL=pessoa@exemplo.com [SENHA=...]"
  task acesso: :environment do
    email = ENV["EMAIL"].presence&.strip&.downcase
    abort "Informe o e-mail: EMAIL=pessoa@exemplo.com bin/rails denfis:acesso" if email.blank?

    if (user = User.find_by(email_address: email))
      user.update!(denfis_access: true)
      puts "Acesso ao Denfis concedido a #{email}. Senha mantida."
      next
    end

    # Sem SENHA, gera uma aleatória e imprime UMA vez — o digest é Argon2id e
    # não há como recuperá-la depois.
    password = ENV["SENHA"].presence || SecureRandom.alphanumeric(16)

    User.create!(
      email_address: email,
      password: password, password_confirmation: password,
      denfis_access: true,
      accounting_access: false     # convidado não vê o módulo contábil
    )

    puts "Usuário criado: #{email}"
    puts "Senha: #{password}" if ENV["SENHA"].blank?
    puts "As finanças dele são separadas das suas — o Denfis escopa tudo por usuário."
  end
end
