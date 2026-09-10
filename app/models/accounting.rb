# Registros do módulo contábil: empresas da carteira, sócios, receita e
# pró-labore mês a mês.
#
# Separado de Tax de propósito. Tax é regra pura, sem banco e sem contexto;
# Accounting é o que a contadora digita. A fronteira mantém o cálculo testável
# sem montar cenário e impede que regra fiscal vaze para dentro de model.
module Accounting
  def self.table_name_prefix = "accounting_"
end
