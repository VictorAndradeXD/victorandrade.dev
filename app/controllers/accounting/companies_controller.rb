class Accounting::CompaniesController < Accounting::BaseController
  before_action :set_company, only: %i[show edit update]

  def index
    @companies = Accounting::Company.active.order(:name)
    @month = selected_month

    # Uma janela por empresa. São duas empresas — não vale montar consulta
    # agregada para isso, e a janela já é a fonte única da verdade.
    @windows = @companies.index_with { |company| company.window(month: @month) }
  end

  def show
    @month  = selected_month
    @window = @company.window(month: @month)
    @recent = @company.competencias.chronological.where(month: ..@month).last(12).reverse
  end

  def new
    @company = Accounting::Company.new(started_on: Date.current.beginning_of_month)
    @company.partners.build
  end

  def create
    @company = Accounting::Company.new(company_params)

    if @company.save
      redirect_to contabil_company_path(@company), notice: "Empresa cadastrada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @company.partners.build
  end

  def update
    if @company.update(company_params)
      redirect_to contabil_company_path(@company), notice: "Empresa atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_company = @company = Accounting::Company.find(params[:id])

    # Ver a nota em CompetenciasController: campos aninhados chegam como hash
    # indexado, que o `expect` com colchete duplo recusa.
    def company_params
      params.require(:company).permit(
        :name, :cnpj, :started_on, :fator_r_eligible, :archived,
        partners_attributes: %i[id name cpf dependents_count _destroy]
      )
    end
end
