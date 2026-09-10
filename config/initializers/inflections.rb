# Be sure to restart your server when you modify this file.

ActiveSupport::Inflector.inflections(:en) do |inflect|
  # "competência" é termo do domínio fiscal brasileiro e não obedece ao
  # inflector inglês: a regra /([ti])a$/ trata palavras terminadas em "ia" como
  # plural latino já formado — media, criteria, bacteria — e devolve
  # "competencia" como plural de si mesma. Sem esta linha o Rails procura a
  # tabela `accounting_competencia`, no singular, e nada funciona.
  inflect.irregular "competencia", "competencias"
end
