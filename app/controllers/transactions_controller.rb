class TransactionsController < ApplicationController
  before_action :require_denfis_access

  before_action :set_transaction, only: %i[show edit update destroy]

  def index
    @month = parse_month
    @transactions = current_user.transactions
      .between(@month.all_month)
      .recent
      .includes(:account, :tag, :items)
  end

  def new
    @transaction = current_user.transactions.build(
      kind: params[:kind].presence_in(Transaction::KINDS) || "expense",
      occurred_on: parse_occurred_on
    )
    @transaction.items.build
  end

  def show; end

  def edit
    @transaction.items.build if @transaction.items.empty?
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)

    if @transaction.save
      redirect_to transactions_path(month: @transaction.occurred_on.strftime("%Y-%m")), notice: "Lançamento criado."
    else
      @transaction.items.build if @transaction.items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @transaction.update(transaction_params)
      redirect_to transactions_path(month: @transaction.occurred_on.strftime("%Y-%m")), notice: "Lançamento atualizado."
    else
      @transaction.items.build if @transaction.items.empty?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    redirect_to transactions_path, notice: "Lançamento removido.", status: :see_other
  end

  private
    def set_transaction
      @transaction = current_user.transactions.find(params[:id])
    end

    def transaction_params
      params.expect(transaction: [
        :kind, :description, :amount, :occurred_on, :account_id, :tag_id,
        items_attributes: [ [ :id, :description, :amount, :_destroy ] ]
      ])
    end

    def parse_month
      Date.strptime(params[:month], "%Y-%m").beginning_of_month
    rescue Date::Error, TypeError
      Date.current.beginning_of_month
    end

    # Vem do calendário do dashboard: "criar um lançamento nesta data".
    def parse_occurred_on
      Date.iso8601(params[:occurred_on])
    rescue Date::Error, TypeError
      Date.current
    end
end
