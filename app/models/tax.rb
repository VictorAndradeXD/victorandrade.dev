# Núcleo de cálculo fiscal do módulo contábil. Regras e tabelas do Simples
# Nacional, INSS e IRRF, mais o fator R e a simulação de pró-labore.
#
# Tudo aqui é puro: entra número, sai número. Não conhece empresa, sócio nem
# competência — esses vêm depois, por cima. Isso é de propósito, porque é a
# parte onde errar custa dinheiro e é a parte que dá para testar exaustivamente
# sem montar cenário nenhum.
#
# As regras de negócio estão escritas em docs/prolabore/regras-fiscais.md.
module Tax
  # Faz o Rails resolver Tax::AnexoBracket para a tabela tax_anexo_brackets.
  def self.table_name_prefix = "tax_"

  # Nenhuma tabela vigente para a data pedida. É erro de dados, não de cálculo:
  # significa que ninguém cadastrou o ano. Melhor estourar do que devolver zero
  # e o número errado circular como se fosse verdade.
  class MissingRule < StandardError
    def self.for(what, date)
      new("Sem #{what} vigente em #{date.strftime('%d/%m/%Y')}. Cadastre a tabela do período.")
    end
  end
end
