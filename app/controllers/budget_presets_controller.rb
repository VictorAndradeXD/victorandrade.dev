# Auto preenchimento. Tudo menos o "Preencher" acontece dentro do turbo-frame
# "budget_presets" da tela do orçamento: o redirect devolve a página inteira e
# o Turbo troca só o frame, então trocar de meta ou cadastrar um gasto não
# rola a tela de volta para o topo.
class BudgetPresetsController < ApplicationController
  include BudgetMonth

  before_action :require_denfis_access
  before_action :set_preset, only: %i[edit update destroy]

  def create
    @preset = current_user.budget_presets.build(preset_params)
    return redirect_to panel_path(@preset.category) if @preset.save

    render_panel_with_errors
  end

  def edit; end

  def update
    return redirect_to panel_path(@preset.category) if @preset.update(preset_params)

    render :edit, status: :unprocessable_entity
  end

  def destroy
    @preset.destroy
    redirect_to panel_path(@preset.category), status: :see_other
  end

  def fill
    account = fill_account
    return redirect_to budget_path(month: budget_month_param), alert: "Escolha a conta dos gastos." unless account

    created = BudgetPreset.fill!(user: current_user, month: budget_month, account: account)
    skipped = current_user.budget_presets.count - created.size

    notice = "#{created.size} gasto(s) lançado(s) em #{helpers.month_label(budget_month)}."
    notice += " #{skipped} já existia(m) no mês e ficou(aram) como estava(m)." if skipped.positive?
    redirect_to budget_path(month: budget_month_param), notice: notice
  end

  private
    def set_preset = @preset = current_user.budget_presets.find(params[:id])

    def preset_params = params.expect(budget_preset: [ :category, :description, :amount ])

    def panel_path(category) = budget_path(month: budget_month_param, categoria: category)

    # Com uma conta só o formulário nem pergunta, como nos lançamentos.
    def fill_account
      accounts = current_user.accounts.active
      return accounts.first if accounts.one?

      accounts.find_by(id: params[:account_id])
    end

    def render_panel_with_errors
      category = Budget.category(@preset.category) || Budget::CATEGORIES.first
      render partial: "budget_presets/panel", status: :unprocessable_entity, locals: {
        budget: Budget.new(current_user, budget_month), category: category, preset: @preset
      }
    end
end
