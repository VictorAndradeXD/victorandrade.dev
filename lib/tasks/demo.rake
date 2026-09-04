namespace :denfis do
  desc "Popula o usuário com dados fictícios variados para inspeção visual (APAGA os dados financeiros dele antes)"
  task demo: :environment do
    user = User.first or abort "Nenhum usuário. Rode bin/rails db:seed antes."

    # Ordem importa: Account tem restrict_with_error enquanto houver lançamento.
    user.transactions.destroy_all
    user.installment_plans.destroy_all
    user.recurring_rules.destroy_all
    user.accounts.destroy_all
    user.tags.destroy_all

    accounts = {
      wallet:   user.accounts.create!(name: "Carteira",        kind: "wallet",      initial_balance: 340.75),
      checking: user.accounts.create!(name: "Nubank Conta",    kind: "checking",    initial_balance: 8_420.10),
      savings:  user.accounts.create!(name: "Itaú Poupança",   kind: "savings",     initial_balance: 27_500),
      nubank:   user.accounts.create!(name: "Cartão Nubank",   kind: "credit_card", initial_balance: 0),
      inter:    user.accounts.create!(name: "Cartão Inter",    kind: "credit_card", initial_balance: 0),
      archived: user.accounts.create!(name: "Conta Antiga BB", kind: "checking",    initial_balance: 0, archived: true)
    }

    tags = {
      alimentacao: user.tags.create!(name: "Alimentação", color: "#f59e0b"),
      moradia:     user.tags.create!(name: "Moradia",     color: "#818cf8"),
      transporte:  user.tags.create!(name: "Transporte",  color: "#38bdf8"),
      saude:       user.tags.create!(name: "Saúde",       color: "#34d399"),
      lazer:       user.tags.create!(name: "Lazer",       color: "#f472b6"),
      educacao:    user.tags.create!(name: "Educação",    color: "#a78bfa"),
      salario:     user.tags.create!(name: "Salário",     color: "#22c55e"),
      investimento: user.tags.create!(name: "Investimentos", color: "#facc15")
    }

    today = Date.current
    month = today.beginning_of_month
    prev  = month.prev_month

    create = lambda do |attrs|
      user.transactions.create!(attrs.reverse_merge(kind: "expense"))
    end

    # ---- Entradas: valores muito diferentes, para testar formatação ----
    create.(description: "Salário",              amount: 9_850.00, kind: "income", occurred_on: month + 4,  account: accounts[:checking], tag: tags[:salario])
    create.(description: "Freela — landing page", amount: 2_400.00, kind: "income", occurred_on: month + 11, account: accounts[:checking], tag: tags[:salario])
    create.(description: "Dividendos ITSA4",     amount: 87.43,    kind: "income", occurred_on: month + 14, account: accounts[:savings],  tag: tags[:investimento])
    create.(description: "Reembolso consulta",   amount: 320.00,   kind: "income", occurred_on: month + 18, account: accounts[:checking], tag: tags[:saude])
    create.(description: "Venda de bicicleta",   amount: 1_150.00, kind: "income", occurred_on: month + 22, account: accounts[:wallet])

    # ---- O caso do cartão: fatura detalhada por dentro, com sobra ----
    fatura = create.(description: "Cartão Nubank", amount: 3_000.00, occurred_on: month + 8, account: accounts[:nubank], tag: tags[:alimentacao])
    fatura.items.create!(description: "gasolina",        amount: 1_000.00)
    fatura.items.create!(description: "mercado do mês",  amount: 640.90)
    fatura.items.create!(description: "farmácia",        amount: 132.50)

    # Fatura detalhada até o último centavo: "sem descrição" deve sumir da lista.
    inter = create.(description: "Cartão Inter", amount: 780.00, occurred_on: month + 12, account: accounts[:inter], tag: tags[:lazer])
    inter.items.create!(description: "cinema",   amount: 96.00)
    inter.items.create!(description: "streaming", amount: 55.90)
    inter.items.create!(description: "restaurante", amount: 628.10)

    # Detalhe de uma parte mínima só, para ver a proporção invertida.
    create.(description: "Compra do mês", amount: 1_240.00, occurred_on: month + 16, account: accounts[:checking], tag: tags[:alimentacao])
      .items.create!(description: "carne", amount: 89.90)

    # ---- Saídas simples, incluindo várias sem tag (segmento "Sem tag" do donut) ----
    [
      [ "Aluguel",              2_200.00, month + 5,  :checking, :moradia ],
      [ "Conta de luz",           187.32, month + 6,  :checking, :moradia ],
      [ "Internet fibra",         119.90, month + 6,  :checking, :moradia ],
      [ "Uber para o aeroporto",   68.40, month + 9,  :wallet,   :transporte ],
      [ "Combustível",            310.00, month + 13, :checking, :transporte ],
      [ "Plano de saúde",         648.00, month + 15, :checking, :saude ],
      [ "Curso de Rails",         397.00, month + 17, :checking, :educacao ],
      [ "Livro técnico",           89.90, month + 17, :nubank,   :educacao ],
      [ "Show",                   240.00, month + 19, :inter,    :lazer ],
      [ "Padaria",                 18.50, month + 20, :wallet,   nil ],
      [ "Estacionamento",          12.00, month + 20, :wallet,   nil ],
      [ "Presente aniversário",   150.00, month + 21, :nubank,   nil ],
      [ "Doação",                  50.00, month + 23, :checking, nil ],
      [ "Manutenção do carro",  1_875.00, month + 24, :checking, :transporte ],
      [ "Cafézinho",                7.50, month + 25, :wallet,   :alimentacao ]
    ].each do |desc, amount, date, account_key, tag_key|
      next if date > month.end_of_month
      create.(description: desc, amount: amount, occurred_on: date,
              account: accounts[account_key], tag: tag_key && tags[tag_key])
    end

    # ---- Mês anterior, para a navegação entre meses mostrar conteúdo ----
    create.(description: "Salário",     amount: 9_850.00, kind: "income", occurred_on: prev + 4, account: accounts[:checking], tag: tags[:salario])
    create.(description: "Aluguel",     amount: 2_200.00, occurred_on: prev + 5,  account: accounts[:checking], tag: tags[:moradia])
    create.(description: "IPVA",        amount: 1_430.00, occurred_on: prev + 10, account: accounts[:checking], tag: tags[:transporte])
    create.(description: "Supermercado", amount: 812.44,  occurred_on: prev + 17, account: accounts[:nubank],   tag: tags[:alimentacao])

    # ---- Recorrências: uma de cada frequência, uma pausada, uma com fim ----
    user.recurring_rules.create!(kind: "expense", description: "Aluguel", amount: 2_200, frequency: "monthly",
                                 day_of_month: 5, starts_on: month - 6.months, account: accounts[:checking], tag: tags[:moradia])
    user.recurring_rules.create!(kind: "expense", description: "Plano de saúde", amount: 648, frequency: "monthly",
                                 day_of_month: 15, starts_on: month - 1.year, account: accounts[:checking], tag: tags[:saude])
    user.recurring_rules.create!(kind: "income", description: "Salário", amount: 9_850, frequency: "monthly",
                                 day_of_month: 4, starts_on: month - 2.years, account: accounts[:checking], tag: tags[:salario])
    user.recurring_rules.create!(kind: "expense", description: "Faxina semanal", amount: 180, frequency: "weekly",
                                 starts_on: month, account: accounts[:wallet])
    user.recurring_rules.create!(kind: "expense", description: "IPTU", amount: 1_890, frequency: "yearly",
                                 starts_on: Date.new(month.year, 1, 10), account: accounts[:checking], tag: tags[:moradia])
    user.recurring_rules.create!(kind: "expense", description: "Academia (pausada)", amount: 129.90, frequency: "monthly",
                                 day_of_month: 8, starts_on: month - 3.months, account: accounts[:checking],
                                 tag: tags[:saude], active: false)
    user.recurring_rules.create!(kind: "expense", description: "Curso de inglês", amount: 380, frequency: "monthly",
                                 day_of_month: 20, starts_on: month - 2.months, ends_on: month + 4.months,
                                 account: accounts[:checking], tag: tags[:educacao])

    # ---- Parcelamentos: divisão exata, inexata e prazo longo ----
    user.installment_plans.create!(kind: "expense", description: "Notebook Dell", total_amount: 6_000,
                                   installments_count: 10, first_due_on: month + 9, account: accounts[:nubank])
    user.installment_plans.create!(kind: "expense", description: "Cadeira ergonômica", total_amount: 1_000,
                                   installments_count: 3, first_due_on: month + 2, account: accounts[:inter], tag: tags[:saude])
    user.installment_plans.create!(kind: "expense", description: "Passagem aérea", total_amount: 2_847.33,
                                   installments_count: 12, first_due_on: month - 1.month, account: accounts[:nubank], tag: tags[:lazer])

    puts "Contas: #{user.accounts.count} | Tags: #{user.tags.count}"
    puts "Lançamentos: #{user.transactions.count} (#{user.transactions.income.count} entradas, #{user.transactions.expense.count} saídas)"
    puts "Com detalhamento: #{user.transactions.where('items_total > 0').count}"
    puts "Recorrências: #{user.recurring_rules.count} | Parcelamentos: #{user.installment_plans.count}"
  end
end
