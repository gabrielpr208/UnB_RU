# Tipo de atributo para valores em reais digitados no formato brasileiro: "20", "20,50", "1.000,00".
# Também aceita o ponto como separador decimal ("20.50"). Texto que não é um valor vira nil.
class ValorMonetario < ActiveModel::Type::Decimal
  MILHAR_COM_PONTO = /\A\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?\z/
  DECIMAL_COM_VIRGULA = /\A\d+(?:,\d{1,2})?\z/
  DECIMAL_COM_PONTO = /\A\d+\.\d{1,2}\z/

  def self.formatar(valor)
    ActiveSupport::NumberHelper.number_to_currency(valor, unit: "R$", separator: ",", delimiter: ".", format: "%u %n")
  end

  def initialize(precision: 10, scale: 2, **)
    super
  end

  private

  def cast_value(valor)
    return super unless valor.is_a?(String)

    texto = valor.strip.delete_prefix("R$").strip

    case texto
    when MILHAR_COM_PONTO, DECIMAL_COM_VIRGULA then super(texto.delete(".").tr(",", "."))
    when DECIMAL_COM_PONTO then super(texto)
    end
  end
end
