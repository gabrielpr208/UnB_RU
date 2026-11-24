# Tipo de atributo para valores em reais digitados no formato brasileiro: "20", "20,50", "1.000,00".
# Também aceita o ponto como separador decimal ("20.50"). Texto que não é um valor vira nil.
class ValorMonetario < ActiveModel::Type::Decimal
  # Valor com ponto separando os milhares, como <tt>"1.000"</tt> ou <tt>"1.000,50"</tt>.
  MILHAR_COM_PONTO = /\A\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?\z/
  # Valor com vírgula decimal opcional, como <tt>"20"</tt> ou <tt>"20,50"</tt>.
  DECIMAL_COM_VIRGULA = /\A\d+(?:,\d{1,2})?\z/
  # Valor com ponto decimal, como <tt>"20.50"</tt>.
  DECIMAL_COM_PONTO = /\A\d+\.\d{1,2}\z/

  # Formata um valor em reais no padrão brasileiro.
  #
  # Argumentos::
  #   - +valor+: número a formatar.
  # Retorno:: +String+ como <tt>"R$ 1.000,50"</tt>.
  # Efeitos colaterais:: nenhum.
  def self.formatar(valor)
    ActiveSupport::NumberHelper.number_to_currency(valor, unit: "R$", separator: ",", delimiter: ".", format: "%u %n")
  end

  # Cria o tipo com 2 casas decimais, como as colunas de valor do banco.
  #
  # Argumentos::
  #   - +precision+: quantidade total de dígitos (padrão: 10).
  #   - +scale+: quantidade de casas decimais (padrão: 2).
  #   - demais opções de <tt>ActiveModel::Type::Decimal</tt>.
  # Retorno:: um ValorMonetario.
  # Efeitos colaterais:: nenhum.
  def initialize(precision: 10, scale: 2, **)
    super
  end

  private

  # Converte o valor recebido em +BigDecimal+. Textos são lidos no formato brasileiro, com ou sem
  # <tt>"R$"</tt>; outros tipos seguem a conversão padrão de <tt>ActiveModel::Type::Decimal</tt>.
  #
  # Argumentos::
  #   - +valor+: texto digitado ou número.
  # Retorno::
  #   - +BigDecimal+ com o valor (ex.: <tt>"1.000,50"</tt> vira +1000.5+);
  #   - +nil+ se o texto não está em nenhum dos formatos aceitos.
  # Efeitos colaterais:: nenhum.
  def cast_value(valor)
    return super unless valor.is_a?(String)

    texto = valor.strip.delete_prefix("R$").strip

    case texto
    when MILHAR_COM_PONTO, DECIMAL_COM_VIRGULA then super(texto.delete(".").tr(",", "."))
    when DECIMAL_COM_PONTO then super(texto)
    end
  end
end
