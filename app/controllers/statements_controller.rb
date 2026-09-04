class StatementsController < ApplicationController
  def show
    @starts_on = parse_date(params[:starts_on], Date.current.beginning_of_month)
    @ends_on   = parse_date(params[:ends_on], Date.current.end_of_month)
    @starts_on, @ends_on = @ends_on, @starts_on if @starts_on > @ends_on

    @account = current_user.accounts.find_by(id: params[:account_id])
    @tag     = current_user.tags.find_by(id: params[:tag_id])
    @kind    = params[:kind].presence_in(Transaction::KINDS)

    @opening = opening_balance
    @rows    = build_rows
    @income  = @rows.sum { |row| row[:transaction].income? ? row[:transaction].amount : 0 }
    @expense = @rows.sum { |row| row[:transaction].expense? ? row[:transaction].amount : 0 }
    @closing = @rows.last&.dig(:balance) || @opening
  end

  private
    def parse_date(value, fallback)
      Date.iso8601(value)
    rescue Date::Error, TypeError
      fallback
    end

    def filtered
      scope = current_user.transactions
      scope = scope.where(account_id: @account.id) if @account
      scope = scope.where(tag_id: @tag.id)         if @tag
      scope = scope.where(kind: @kind)             if @kind
      scope
    end

    # Saldo com que o período começa: aportes iniciais das contas em vista mais
    # tudo que aconteceu antes da data inicial. Sem isso o saldo acumulado da
    # tabela começaria do zero e não bateria com a conta real.
    def opening_balance
      accounts = @account ? [ @account ] : current_user.accounts.to_a
      initial = accounts.sum(&:initial_balance)

      initial + filtered.where(occurred_on: ...@starts_on).signed_total
    end

    # Cada linha carrega o saldo acumulado até ela, em ordem cronológica.
    def build_rows
      balance = @opening

      filtered
        .includes(:account, :tag, :items)
        .where(occurred_on: @starts_on..@ends_on)
        .order(:occurred_on, :id)
        .map do |transaction|
          balance += transaction.signed_amount
          { transaction: transaction, balance: balance }
        end
    end
end
