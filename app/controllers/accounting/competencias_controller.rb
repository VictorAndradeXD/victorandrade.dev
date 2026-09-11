# Lançamento mensal: quanto a empresa faturou e quanto cada sócio recebeu de
# pró-labore. É o que alimenta a janela de 12 meses.
class Accounting::CompetenciasController < Accounting::BaseController
  before_action :set_company
  before_action :set_competencia, only: %i[edit update]

  def index
    @competencias = @company.competencias.chronological.reverse
  end

  def new
    @competencia = @company.competencias.new(month: next_open_month)
    build_missing_prolabores
  end

  def create
    @competencia = @company.competencias.new(competencia_params)

    if @competencia.save
      redirect_to contabil_company_competencias_path(@company), notice: "Competência lançada."
    else
      build_missing_prolabores
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_missing_prolabores
  end

  def update
    if @competencia.update(competencia_params)
      redirect_to contabil_company_competencias_path(@company), notice: "Competência atualizada."
    else
      build_missing_prolabores
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_company = @company = Accounting::Company.find(params[:company_id])

    def set_competencia = @competencia = @company.competencias.find(params[:id])

    # O mês seguinte ao último lançado, ou o corrente se não houver nenhum.
    def next_open_month
      last = @company.competencias.maximum(:month)
      last ? (last >> 1) : Date.current.beginning_of_month
    end

    # Um campo de pró-labore por sócio, mesmo os que ainda não têm lançamento
    # no mês — senão o formulário só deixaria editar quem já existe.
    def build_missing_prolabores
      existing = @competencia.prolabores.map(&:partner_id)

      @company.partners.order(:name).each do |partner|
        next if existing.include?(partner.id)

        @competencia.prolabores.build(partner: partner)
      end
    end

    # `permit`, e não `expect`: os campos aninhados chegam como hash indexado
    # por posição ({"0" => {...}}), e o expect com colchete duplo exige um array.
    def competencia_params
      params.require(:competencia).permit(
        :month, :gross_revenue,
        prolabores_attributes: %i[id partner_id gross _destroy]
      )
    end
end
