# Extrato do estudante: recargas confirmadas (entradas) e refeições (saídas), da mais recente para a
# mais antiga. Recargas PIX pendentes ou expiradas ficam de fora, porque não mexeram no saldo.
#
# Filtros (todos opcionais e combináveis):
# - tipo: só recargas ou só refeições
# - período: data inicial e data final, ambas inclusivas
# - faixa de valor: compara o valor sem o sinal, então "de R$ 4,00 a R$ 10,00" pega uma refeição de R$ 4,50
class Extrato
  include ActiveModel::Model
  include ActiveModel::Attributes

  TIPOS = %w[ todos recargas refeicoes ].freeze
  DETALHE_DA_RECARGA = { "pix" => "PIX", "cartao" => "Cartão de crédito" }.freeze

  attribute :tipo, :string, default: "todos"
  attribute :data_inicial, :date
  attribute :data_final, :date
  # Ficam como texto para o formulário mostrar de volta o que foi digitado, mesmo quando é inválido.
  attribute :valor_minimo, :string
  attribute :valor_maximo, :string

  attr_accessor :estudante

  validate :validar_periodo
  validate :validar_faixa_de_valor

  # Um tipo desconhecido (ex.: alterado na URL) mostra todas as movimentações.
  def tipo=(valor)
    super(TIPOS.include?(valor) ? valor : "todos")
  end

  def movimentacoes
    @movimentacoes ||= (recargas + refeicoes).sort_by(&:data_hora).reverse
  end

  def entradas
    movimentacoes.select(&:recarga?).sum(&:valor)
  end

  def saidas
    movimentacoes.select(&:refeicao?).sum(&:valor)
  end

  def filtrado?
    tipo != "todos" || [ data_inicial, data_final, valor_minimo, valor_maximo ].any?(&:present?)
  end

  private

  def recargas
    return [] if tipo == "refeicoes"

    filtrar(estudante.recargas.confirmada, coluna_da_data: :confirmada_em, coluna_do_valor: :valor).map do |recarga|
      Movimentacao.new(tipo: :recarga, valor: recarga.valor, data_hora: recarga.confirmada_em,
                       detalhe: DETALHE_DA_RECARGA.fetch(recarga.metodo))
    end
  end

  def refeicoes
    return [] if tipo == "recargas"

    filtrar(estudante.acessos, coluna_da_data: :data_hora, coluna_do_valor: :valor_cobrado).map do |acesso|
      Movimentacao.new(tipo: :refeicao, valor: -acesso.valor_cobrado, data_hora: acesso.data_hora, detalhe: nil)
    end
  end

  def filtrar(relacao, coluna_da_data:, coluna_do_valor:)
    if data_inicial || data_final
      relacao = relacao.where(coluna_da_data => data_inicial&.beginning_of_day..data_final&.end_of_day)
    end
    relacao = relacao.where(coluna_do_valor => minimo..maximo) if minimo || maximo
    relacao
  end

  def minimo
    ValorMonetario.new.cast(valor_minimo)
  end

  def maximo
    ValorMonetario.new.cast(valor_maximo)
  end

  def validar_periodo
    return unless data_inicial && data_final && data_inicial > data_final

    errors.add(:data_final, "A data final não pode ser anterior à data inicial")
  end

  def validar_faixa_de_valor
    errors.add(:valor_minimo, "Informe um valor numérico válido") if valor_minimo.present? && minimo.nil?
    errors.add(:valor_maximo, "Informe um valor numérico válido") if valor_maximo.present? && maximo.nil?
    return unless minimo && maximo && minimo > maximo

    errors.add(:valor_maximo, "O valor máximo não pode ser menor que o valor mínimo")
  end
end
