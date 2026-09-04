class DashboardController < ApplicationController
  def show
    @month = parse_month
    @range = @month.all_month

    scope = current_user.transactions.between(@range)

    @income  = scope.income.sum(:amount)
    @expense = scope.expense.sum(:amount)
    @result  = @income - @expense
    @balance = current_user.accounts.active.sum { |account| account.balance(up_to: @range.end) }

    @daily      = scope.group(:occurred_on).sum(Arel.sql(Transaction::SIGNED_AMOUNT_SQL))
    @by_tag     = expense_by_tag(scope)
    @untagged   = scope.expense.where(tag_id: nil).sum(:amount)
    @recent     = scope.recent.includes(:account, :tag).limit(8)
  end

  # Lançamentos de um único dia. Responde tanto dentro do turbo-frame do
  # dashboard quanto como página inteira, se alguém abrir a URL direto.
  def day
    @date = Date.iso8601(params[:date])
    @transactions = current_user.transactions
      .where(occurred_on: @date)
      .recent
      .includes(:account, :tag, :items)
    @net = @transactions.sum(&:signed_amount)
  rescue Date::Error
    redirect_to root_path
  end

  private
    def parse_month
      Date.strptime(params[:month], "%Y-%m").beginning_of_month
    rescue Date::Error, TypeError
      Date.current.beginning_of_month
    end

    # [[tag, total], ...] em ordem decrescente, só despesas.
    def expense_by_tag(scope)
      totals = scope.expense.where.not(tag_id: nil).group(:tag_id).sum(:amount)
      tags = current_user.tags.where(id: totals.keys).index_by(&:id)

      totals.sort_by { |_, total| -total }.filter_map do |tag_id, total|
        tag = tags[tag_id]
        [ tag, total ] if tag
      end
    end
end
