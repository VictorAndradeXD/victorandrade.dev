Rails.application.routes.draw do
  resource  :session
  resources :passwords, param: :token

  resources :transactions
  resources :accounts
  resources :tags
  resources :recurring_rules do
    member { post :materialize }
  end
  resources :installment_plans, only: %i[index new create destroy]

  resource :statement, only: :show, path: "extrato"

  # Detalhe de um dia do calendário, carregado num turbo-frame do dashboard.
  get "dia/:date", to: "dashboard#day", as: :day, constraints: { date: /\d{4}-\d{2}-\d{2}/ }

  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
end
