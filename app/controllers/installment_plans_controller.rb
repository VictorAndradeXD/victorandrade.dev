class InstallmentPlansController < ApplicationController
  def index
    @plans = current_user.installment_plans.includes(:account, :tag).order(created_at: :desc)
  end

  def new
    @plan = current_user.installment_plans.build(
      kind: "expense", installments_count: 2, first_due_on: Date.current
    )
  end

  def create
    @plan = current_user.installment_plans.build(plan_params)
    return redirect_to installment_plans_path, notice: "Parcelamento criado." if @plan.save

    render :new, status: :unprocessable_entity
  end

  def destroy
    plan = current_user.installment_plans.find(params[:id])
    plan.destroy
    redirect_to installment_plans_path, notice: "Parcelamento e suas parcelas removidos.", status: :see_other
  end

  private
    def plan_params
      params.expect(installment_plan: [
        :kind, :description, :total_amount, :installments_count, :first_due_on, :account_id, :tag_id
      ])
    end
end
