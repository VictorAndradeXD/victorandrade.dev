# Dígitos verificadores de CPF e CNPJ.
#
# Vale a pena validar de verdade, e não só o formato: um CNPJ com dígito errado
# é quase sempre erro de digitação, e aqui ele viraria cálculo atribuído à
# empresa errada. O dígito pega isso na hora do cadastro.
module BrDocument
  module_function

  def digits(value) = value.to_s.gsub(/\D/, "")

  def valid_cpf?(value)
    n = digits(value)
    return false unless n.length == 11
    return false if n.chars.uniq.one?   # 111.111.111-11 passa na conta, mas não existe

    [ 9, 10 ].all? do |position|
      weights = (position + 1).downto(2).to_a
      sum = weights.each_with_index.sum { |weight, i| n[i].to_i * weight }

      (sum * 10) % 11 % 10 == n[position].to_i
    end
  end

  CNPJ_WEIGHTS = {
    12 => [ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ],
    13 => [ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ]
  }.freeze

  def valid_cnpj?(value)
    n = digits(value)
    return false unless n.length == 14
    return false if n.chars.uniq.one?

    CNPJ_WEIGHTS.all? do |position, weights|
      sum = weights.each_with_index.sum { |weight, i| n[i].to_i * weight }
      remainder = sum % 11

      (remainder < 2 ? 0 : 11 - remainder) == n[position].to_i
    end
  end

  def format_cnpj(value)
    n = digits(value)
    return value.to_s unless n.length == 14

    "#{n[0..1]}.#{n[2..4]}.#{n[5..7]}/#{n[8..11]}-#{n[12..13]}"
  end

  def format_cpf(value)
    n = digits(value)
    return value.to_s unless n.length == 11

    "#{n[0..2]}.#{n[3..5]}.#{n[6..8]}-#{n[9..10]}"
  end
end
