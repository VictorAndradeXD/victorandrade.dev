Rails.application.routes.draw do
  resource  :session
  resources :passwords, param: :token

  # O portfólio é a home do site. Denfis, blog e o módulo contábil ficam cada
  # um sob o seu próprio prefixo.
  root "portfolio#show"

  get "blog", to: "blog#index"

  # Módulo contábil. A raiz fica solta para `contabil_path` seguir apontando
  # para ela; o resto vive no scope abaixo, que prefixa URL e helper.
  get "contabil", to: "accounting/companies#index"

  scope module: "accounting", path: "contabil", as: :contabil do
    resources :companies, path: "empresas", except: :destroy do
      resources :competencias, path: "competencias", only: %i[index new create edit update]
    end
  end

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
    resources :installment_plans, only: %i[index new create destroy]

    resource :statement, only: :show, path: "extrato"

    # Orçamento doméstico: metas em % da renda, comparadas com o que foi gasto.
    resource :budget, only: :show, path: "orcamento"
    resource :budget_goals, only: %i[edit update], path: "orcamento/metas", path_names: { edit: "" }
    resource :budget_income, only: :update, path: "orcamento/renda"
    resources :budget_presets, only: %i[create edit update destroy], path: "orcamento/auto-preenchimento" do
      collection { post :fill, path: "preencher" }
    end
  end

  # App instalável no celular (PWA). O manifest aponta para /app, que manda
  # cada pessoa para o módulo que ela pode abrir.
  get "app", to: "launch#show", as: :app_launch
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "up" => "rails/health#show", as: :rails_health_check
end
