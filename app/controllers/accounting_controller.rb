# Módulo de pró-labore e fator R. Privado: quem entra aqui é a contadora.
# As regras de negócio estão em docs/prolabore/regras-fiscais.md.
class AccountingController < ApplicationController
  before_action :require_accounting_access
  layout "accounting"

  def index
  end
end
