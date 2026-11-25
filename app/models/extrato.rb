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

  # Valores aceitos no filtro de tipo.
  TIPOS = %w[ todos recargas refeicoes ].freeze
  # Texto que acompanha cada recarga no extrato, conforme a forma de pagamento.
  DETALHE_DA_RECARGA = { "pix" => "PIX", "cartao" => "Cartão de crédito" }.freeze

  attribute :tipo, :string, default: "todos"
  attribute :data_inicial, :date
  attribute :data_final, :date
  # Ficam como texto para o formulário mostrar de volta o que foi digitado, mesmo quando é inválido.
  attribute :valor_minimo, :string
  attribute :valor_maximo, :string

  # Estudante dono do extrato.
  attr_accessor :estudante

  validate :validar_periodo
  validate :validar_faixa_de_valor

  # Define o filtro de tipo. Um tipo desconhecido (ex.: alterado na URL) mostra todas as movimentações.
  #
  # Argumentos::
  #   - +valor+: tipo escolhido (<tt>"todos"</tt>, <tt>"recargas"</tt> ou <tt>"refeicoes"</tt>).
  # Retorno:: o valor recebido.
  # Efeitos colaterais:: altera o atributo +tipo+ (para <tt>"todos"</tt> se o valor não estiver em TIPOS).
  def tipo=(valor)
    super(TIPOS.include?(valor) ? valor : "todos")
  end

  # Movimentações do estudante que passam pelos filtros, da mais recente para a mais antiga.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Array+ de Movimentacao, memorizado entre as chamadas.
  # Efeitos colaterais:: nenhum (apenas consulta o banco na primeira chamada).
  def movimentacoes
    @movimentacoes ||= (recargas + refeicoes).sort_by(&:data_hora).reverse
  end

  # Soma das recargas exibidas no extrato.
  #
  # Argumentos:: nenhum.
  # Retorno:: o total das entradas, em reais (+0+ quando não há recargas).
  # Efeitos colaterais:: nenhum.
  def entradas
    movimentacoes.select(&:recarga?).sum(&:valor)
  end

  # Soma das refeições exibidas no extrato.
  #
  # Argumentos:: nenhum.
  # Retorno:: o total das saídas, em reais, com sinal negativo (+0+ quando não há refeições).
  # Efeitos colaterais:: nenhum.
  def saidas
    movimentacoes.select(&:refeicao?).sum(&:valor)
  end

  # Diz se algum filtro foi aplicado.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ se o tipo não é <tt>"todos"</tt> ou se há período ou faixa de valor; +false+ caso contrário.
  # Efeitos colaterais:: nenhum.
  def filtrado?
    tipo != "todos" || [ data_inicial, data_final, valor_minimo, valor_maximo ].any?(&:present?)
  end

  # Valor mínimo da faixa, convertido do texto digitado (ver ValorMonetario).
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - +BigDecimal+ com o valor;
  #   - +nil+ quando o campo está em branco ou não é um valor válido.
  # Efeitos colaterais:: nenhum.
  def minimo
    ValorMonetario.new.cast(valor_minimo)
  end

  # Valor máximo da faixa, convertido do texto digitado (ver ValorMonetario).
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - +BigDecimal+ com o valor;
  #   - +nil+ quando o campo está em branco ou não é um valor válido.
  # Efeitos colaterais:: nenhum.
  def maximo
    ValorMonetario.new.cast(valor_maximo)
  end

  private

  # Recargas confirmadas do estudante que passam pelos filtros.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Array+ de Movimentacao do tipo +:recarga+ (vazio quando o filtro é só de refeições).
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def recargas
    return [] if tipo == "refeicoes"

    filtrar(estudante.recargas.confirmada, coluna_da_data: :confirmada_em, coluna_do_valor: :valor).map do |recarga|
      Movimentacao.new(tipo: :recarga, valor: recarga.valor, data_hora: recarga.confirmada_em,
                       detalhe: DETALHE_DA_RECARGA.fetch(recarga.metodo))
    end
  end

  # Refeições (acessos) do estudante que passam pelos filtros.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   +Array+ de Movimentacao do tipo +:refeicao+, com valor negativo (vazio quando o filtro é só de recargas).
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def refeicoes
    return [] if tipo == "recargas"

    filtrar(estudante.acessos, coluna_da_data: :data_hora, coluna_do_valor: :valor_cobrado).map do |acesso|
      Movimentacao.new(tipo: :refeicao, valor: -acesso.valor_cobrado, data_hora: acesso.data_hora, detalhe: nil)
    end
  end

  # Aplica o período e a faixa de valor a uma consulta.
  #
  # Argumentos::
  #   - +relacao+: consulta de recargas ou de acessos.
  #   - +coluna_da_data+: coluna comparada com o período (ex.: +:confirmada_em+).
  #   - +coluna_do_valor+: coluna comparada com a faixa de valor (ex.: +:valor_cobrado+).
  # Retorno:: <tt>ActiveRecord::Relation</tt> com as condições dos filtros preenchidos.
  # Efeitos colaterais:: nenhum.
  def filtrar(relacao, coluna_da_data:, coluna_do_valor:)
    if data_inicial || data_final
      relacao = relacao.where(coluna_da_data => data_inicial&.beginning_of_day..data_final&.end_of_day)
    end
    relacao = relacao.where(coluna_do_valor => minimo..maximo) if minimo || maximo
    relacao
  end

  # Validação do período: a data final não pode ser anterior à data inicial.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: adiciona um erro em +data_final+ quando o período é invertido.
  def validar_periodo
    return unless data_inicial && data_final && data_inicial > data_final

    errors.add(:data_final, "A data final não pode ser anterior à data inicial")
  end

  # Validação da faixa de valor: os valores precisam ser numéricos e o máximo não pode ser menor que o mínimo.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   adiciona erros em +valor_minimo+ e +valor_maximo+ quando não são numéricos, e em +valor_maximo+ quando
  #   a faixa é invertida.
  def validar_faixa_de_valor
    validar_valor_numerico(:valor_minimo, minimo)
    validar_valor_numerico(:valor_maximo, maximo)
    return unless minimo && maximo && minimo > maximo

    errors.add(:valor_maximo, "O valor máximo não pode ser menor que o valor mínimo")
  end

  # Confere se um campo da faixa de valor preenchido virou um número.
  #
  # Argumentos::
  #   - +campo+: nome do campo (+:valor_minimo+ ou +:valor_maximo+).
  #   - +valor+: valor já convertido do campo (+nil+ se a conversão falhou).
  # Retorno:: nenhum.
  # Efeitos colaterais:: adiciona um erro no campo quando ele está preenchido, mas não é um valor válido.
  def validar_valor_numerico(campo, valor)
    errors.add(campo, "Informe um valor numérico válido") if public_send(campo).present? && valor.nil?
  end
end
