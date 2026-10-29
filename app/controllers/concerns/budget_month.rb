# O mês do orçamento vem em ?month=2026-10, como no dashboard. As telas do
# orçamento passam o mês adiante em todo formulário, para que salvar uma meta
# ou um modelo devolva a pessoa para o mês em que ela estava.
module BudgetMonth
  extend ActiveSupport::Concern

  private
    def budget_month
      @budget_month ||= begin
        Date.strptime(params[:month], "%Y-%m").beginning_of_month
      rescue Date::Error, TypeError
        Date.current.beginning_of_month
      end
    end

    def budget_month_param = budget_month.strftime("%Y-%m")
end
