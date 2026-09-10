# Fator R: folha dos últimos 12 meses dividida pela receita bruta dos últimos 12.
#
# É DEGRAU, não rampa. Igual ou acima do limite a empresa tributa pelo Anexo III;
# abaixo, pelo Anexo V. Não existe crédito parcial — pagar 20% de folha custa
# INSS e IRRF e mantém a empresa no anexo caro, que é o pior dos cenários.
class Tax::FatorR
  THRESHOLD = BigDecimal("0.28")

  attr_reader :folha12, :rbt12

  def initialize(folha12:, rbt12:)
    @folha12 = folha12.to_d
    @rbt12   = rbt12.to_d
  end

  # Valor para exibir, arredondado.
  def value = ratio.round(6)

  # A decisão usa a razão CRUA, nunca o `value`. Arredondar antes de comparar
  # faz 27,999995% virar 28,000000% e classifica a empresa no anexo barato sem
  # ela ter direito — erro que só apareceria numa fiscalização.
  def reaches? = ratio >= THRESHOLD

  def anexo = reaches? ? Tax::AnexoBracket::ANEXO_III : Tax::AnexoBracket::ANEXO_V

  # Folha anual necessária para encostar no limite.
  def required_folha = (rbt12 * THRESHOLD).round(2)

  def missing_folha = [ required_folha - folha12, 0.to_d ].max

  private
    # Sem receita não há razão a calcular. Devolve zero em vez de estourar
    # porque empresa recém-aberta passa por aqui antes de faturar o primeiro real.
    def ratio
      return 0.to_d if rbt12 <= 0

      folha12 / rbt12
    end
end
