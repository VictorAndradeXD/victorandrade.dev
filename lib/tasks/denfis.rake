namespace :denfis do
  desc "Cria um usuário: bin/rails 'denfis:create_user[email@exemplo.com]'"
  task :create_user, [ :email ] => :environment do |_task, args|
    email = args[:email] or abort "Informe o e-mail: bin/rails 'denfis:create_user[email@exemplo.com]'"
    abort "Usuário #{email} já existe." if User.exists?(email_address: email)

    password = ENV["PASSWORD"].presence || SecureRandom.alphanumeric(16)
    User.create!(email_address: email, password: password, password_confirmation: password)

    puts "Usuário criado: #{email}"
    puts "Senha: #{password}" unless ENV["PASSWORD"].present?
  end

  desc "Gera os lançamentos das recorrências ativas para o mês atual"
  task materialize_recurring: :environment do
    range = Date.current.all_month
    created = RecurringRule.active.sum { |rule| rule.materialize!(range).size }

    puts "#{created} lançamento(s) gerado(s) para #{range.begin.strftime('%m/%Y')}."
  end
end
