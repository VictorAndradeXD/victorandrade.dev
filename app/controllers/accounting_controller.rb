# Placeholder do módulo de pró-labore. Público enquanto é só uma página de
# "em construção"; ganha autenticação junto com a primeira tela real.
# As regras de negócio já estão em docs/prolabore/regras-fiscais.md.
class AccountingController < ApplicationController
  allow_unauthenticated_access
  layout "public"

  def index
  end
end
