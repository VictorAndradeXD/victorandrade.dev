# Base de todo controller do módulo contábil: exige a permissão e usa o layout
# próprio. Herdar daqui é o que garante que ninguém esqueça o before_action.
class Accounting::BaseController < ApplicationController
  before_action :require_accounting_access

  layout "accounting"

  private
    # Competência em foco. Vem da URL como "2026-09"; sem parâmetro, o mês
    # corrente. Mês inválido não vira erro 500 — cai no corrente.
    def selected_month
      @selected_month ||= begin
        Date.strptime(params[:month].to_s, "%Y-%m")
      rescue Date::Error, TypeError
        Date.current.beginning_of_month
      end
    end
end
