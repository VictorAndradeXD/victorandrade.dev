Rails.application.routes.draw do
  resource  :session
  resources :passwords, param: :token

  # O portfólio é a home do site. Denfis, blog e o módulo contábil ficam cada
  # um sob o seu próprio prefixo.
  root "portfolio#show"

  get "blog",     to: "blog#index"
  get "contabil", to: "accounting#index"

  # `scope path:` sem `as:` é de propósito: as URLs ganham o prefixo /denfis,
  # mas os helpers continuam sendo transactions_path, accounts_path e companhia,
  # o que mantém as views do Denfis intactas.
  scope path: "denfis" do
    get "/", to: "dashboard#show", as: :denfis_root

    # Detalhe de um dia do calendário, carregado num turbo-frame do dashboard.
    get "dia/:date", to: "dashboard#day", as: :day, constraints: { date: /\d{4}-\d{2}-\d{2}/ }

    resources :transactions
    resources :accounts
    resources :tags
    resources :recurring_rules do
      member { post :materialize }
    end
    resources :installment_plans, only: %i[index new create destroy]

    resource :statement, only: :show, path: "extrato"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
