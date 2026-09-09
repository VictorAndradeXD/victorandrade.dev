namespace :contabil do
  desc "Concede acesso ao módulo contábil. EMAIL=contadora@exemplo.com [SENHA=...]"
  task acesso: :environment do
    email = ENV["EMAIL"].presence
    abort "Informe o e-mail: EMAIL=contadora@exemplo.com bin/rails contabil:acesso" if email.blank?

    email = email.strip.downcase
    user  = User.find_by(email_address: email)

    if user
      user.update!(accounting_access: true)
      puts "Acesso ao contábil concedido a #{email}. Senha mantida."
    else
      # Sem SENHA, gera uma aleatória e imprime uma única vez — o digest é
      # Argon2id e não há como recuperá-la depois.
      password = ENV["SENHA"].presence || SecureRandom.alphanumeric(16)

      User.create!(
        email_address: email,
        password: password, password_confirmation: password,
        denfis_access: false,          # a contadora não vê finanças pessoais
        accounting_access: true
      )

      puts "Usuário criado: #{email}"
      puts "Senha: #{password}" if ENV["SENHA"].blank?
      puts "Sem acesso ao Denfis — só ao módulo contábil."
    end
  end

  desc "Revoga o acesso ao módulo contábil. EMAIL=..."
  task revogar: :environment do
    email = ENV["EMAIL"].presence&.strip&.downcase
    abort "Informe o e-mail: EMAIL=... bin/rails contabil:revogar" if email.blank?

    user = User.find_by(email_address: email)
    abort "Usuário #{email} não encontrado." if user.nil?

    # O check constraint impede deixar alguém sem módulo nenhum; avisa em vez
    # de estourar uma exceção do Postgres na cara de quem rodou a tarefa.
    if !user.denfis_access?
      abort "#{email} só tem o contábil. Revogar deixaria a conta sem acesso a nada — apague o usuário."
    end

    user.update!(accounting_access: false)
    puts "Acesso ao contábil revogado de #{email}."
  end
end
