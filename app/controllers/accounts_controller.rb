class AccountsController < ApplicationController
  before_action :set_account, only: %i[edit update destroy]

  def index
    @accounts = current_user.accounts.order(:archived, :name)
  end

  def new    = @account = current_user.accounts.build(kind: "checking")
  def edit; end

  def create
    @account = current_user.accounts.build(account_params)
    return redirect_to accounts_path, notice: "Conta criada." if @account.save

    render :new, status: :unprocessable_entity
  end

  def update
    return redirect_to accounts_path, notice: "Conta atualizada." if @account.update(account_params)

    render :edit, status: :unprocessable_entity
  end

  def destroy
    if @account.destroy
      redirect_to accounts_path, notice: "Conta removida.", status: :see_other
    else
      redirect_to accounts_path, alert: @account.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_account = @account = current_user.accounts.find(params[:id])

    def account_params
      params.expect(account: [ :name, :kind, :initial_balance, :archived ])
    end
end
