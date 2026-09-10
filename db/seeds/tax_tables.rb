# Tabelas fiscais do módulo contábil. Idempotente: roda de novo sem duplicar.
#
# ================== LEIA ANTES DE CONFIAR NOS NÚMEROS ==================
# Os Anexos III e V vêm da LC 123 e são estáveis: entram com vigência aberta.
#
# INSS e IRRF mudam TODO ANO por ato do governo. Os valores de 2026 aqui são
# ARRASTADOS de 2025 como marcador de lugar — NÃO são os números oficiais de
# 2026. A exceção é a isenção de IRRF até R$5.000 com redução parcial até
# R$7.350, que é a regra de 2026 (Lei 15.270/2025).
#
# A contadora precisa conferir e corrigir antes de qualquer número sair daqui
# como oficial. Checklist em docs/prolabore/regras-fiscais.md.
# =======================================================================

def upsert_anexo(anexo, faixas)
  faixas.each do |from, to, rate, deduction|
    bracket = Tax::AnexoBracket.find_or_initialize_by(
      anexo: anexo, rbt12_from: from, valid_from: Date.new(2018, 1, 1)
    )
    bracket.update!(rbt12_to: to, rate: rate, deduction: deduction, valid_to: nil)
  end
end

# [de, até (nil = última), alíquota nominal, parcela a deduzir]
upsert_anexo("III", [
  [ 0,           180_000,   0.060, 0 ],
  [ 180_000.01,  360_000,   0.112, 9_360 ],
  [ 360_000.01,  720_000,   0.135, 17_640 ],
  [ 720_000.01,  1_800_000, 0.160, 35_640 ],
  [ 1_800_000.01, 3_600_000, 0.210, 125_640 ],
  [ 3_600_000.01, 4_800_000, 0.330, 648_000 ]
])

upsert_anexo("V", [
  [ 0,           180_000,   0.155, 0 ],
  [ 180_000.01,  360_000,   0.180, 4_500 ],
  [ 360_000.01,  720_000,   0.195, 9_900 ],
  [ 720_000.01,  1_800_000, 0.205, 17_100 ],
  [ 1_800_000.01, 3_600_000, 0.230, 62_100 ],
  [ 3_600_000.01, 4_800_000, 0.305, 540_000 ]
])

# --- INSS -------------------------------------------------------------------
# 2025: valores reais. 2026: arrastados, PENDENTES de conferência.
{
  Date.new(2025, 1, 1) => [ Date.new(2025, 12, 31), 8_157.41, 1_518.00 ],
  Date.new(2026, 1, 1) => [ nil,                    8_157.41, 1_518.00 ]
}.each do |valid_from, (valid_to, ceiling, minimum_wage)|
  rule = Tax::InssRule.find_or_initialize_by(valid_from: valid_from)
  rule.update!(rate: 0.11, ceiling: ceiling, minimum_wage: minimum_wage, valid_to: valid_to)
end

# --- IRRF -------------------------------------------------------------------
# Faixas da tabela vigente desde maio/2025, mantidas em 2026. O que muda em
# 2026 é a isenção até R$5.000 com redução parcial até R$7.350.
IRRF_BRACKETS = [
  [ 0,       2_428.80, 0.000, 0 ],
  [ 2_428.81, 2_826.65, 0.075, 182.16 ],
  [ 2_826.66, 3_751.05, 0.150, 394.16 ],
  [ 3_751.06, 4_664.68, 0.225, 675.49 ],
  [ 4_664.69, nil,      0.275, 908.73 ]
].freeze

{
  Date.new(2025, 5, 1) => { valid_to: Date.new(2025, 12, 31), exempt_up_to: nil,   phase_out_up_to: nil },
  Date.new(2026, 1, 1) => { valid_to: nil,                    exempt_up_to: 5_000, phase_out_up_to: 7_350 }
}.each do |valid_from, attrs|
  rule = Tax::IrrfRule.find_or_initialize_by(valid_from: valid_from)
  rule.update!(dependent_deduction: 189.59, simplified_discount: 607.20, **attrs)

  IRRF_BRACKETS.each do |from, to, rate, deduction|
    bracket = rule.brackets.find_or_initialize_by(base_from: from)
    bracket.update!(base_to: to, rate: rate, deduction: deduction)
  end
end

puts "Tabelas fiscais: #{Tax::AnexoBracket.count} faixas de anexo, " \
     "#{Tax::InssRule.count} regra(s) de INSS, #{Tax::IrrfRule.count} de IRRF " \
     "(#{Tax::IrrfBracket.count} faixas)."
puts "ATENÇÃO: INSS e IRRF de 2026 são valores arrastados de 2025 — conferir com a contadora."
