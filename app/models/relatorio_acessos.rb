# Histórico de todos os acessos dos restaurantes, para o administrador (features/relatorio_global.feature).
#
# Filtros opcionais: restaurante e, dentro dele, uma catraca. A catraca só vale junto com o restaurante
# dela; uma catraca de outro restaurante (ex.: o restaurante foi trocado no formulário) é ignorada.
#
# O agrupamento conta os acessos filtrados por restaurante ou por catraca.
class RelatorioAcessos
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Valores aceitos no agrupamento.
  AGRUPAMENTOS = %w[ restaurante catraca ].freeze

  attribute :restaurante_id, :integer
  attribute :catraca_id, :integer
  attribute :agrupar, :string

  # Define o agrupamento. Um agrupamento desconhecido (ex.: alterado na URL) mostra a lista sem totais.
  #
  # Argumentos::
  #   - +valor+: agrupamento escolhido (<tt>"restaurante"</tt> ou <tt>"catraca"</tt>).
  # Retorno:: o valor recebido.
  # Efeitos colaterais:: altera o atributo +agrupar+ (para +nil+ se o valor não estiver em AGRUPAMENTOS).
  def agrupar=(valor)
    super(AGRUPAMENTOS.include?(valor) ? valor : nil)
  end

  # Restaurante escolhido no filtro.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - o Restaurante de +restaurante_id+;
  #   - +nil+ se nenhum foi escolhido ou se o id não existe. O resultado é memorizado entre as chamadas.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def restaurante
    return @restaurante if defined?(@restaurante)

    @restaurante = (Restaurante.find_by(id: restaurante_id) if restaurante_id)
  end

  # Catraca escolhida no filtro, desde que seja do restaurante escolhido.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - a Catraca de +catraca_id+;
  #   - +nil+ se não há restaurante, se nenhuma catraca foi escolhida ou se ela é de outro restaurante.
  #     O resultado é memorizado entre as chamadas.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def catraca
    return @catraca if defined?(@catraca)

    @catraca = (restaurante.catracas.find_by(id: catraca_id) if restaurante && catraca_id)
  end

  # Catracas que podem ser escolhidas no filtro: só as do restaurante selecionado.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   <tt>ActiveRecord::Relation</tt> com as catracas do restaurante, por identificador, ou vazia se nenhum
  #   restaurante foi escolhido.
  # Efeitos colaterais:: nenhum.
  def catracas_disponiveis
    restaurante ? restaurante.catracas.order(:identificador) : Catraca.none
  end

  # Diz se algum filtro foi aplicado.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ se um restaurante foi escolhido; +false+ caso contrário.
  # Efeitos colaterais:: nenhum.
  def filtrado?
    restaurante_id.present?
  end

  # Acessos que passam pelos filtros, do mais recente para o mais antigo, já com o estudante, a catraca e o
  # restaurante carregados.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Array+ de Acesso, memorizado entre as chamadas.
  # Efeitos colaterais:: nenhum (apenas consulta o banco na primeira chamada).
  def acessos
    @acessos ||= filtrados.includes(:estudante, catraca: :restaurante).order(data_hora: :desc, id: :desc).to_a
  end

  # Quantidade de acessos filtrados em cada grupo, conforme o agrupamento escolhido.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   +Array+ de pares <tt>[grupo, total]</tt> em ordem alfabética, ex.:
  #   <tt>[["RU Darcy Ribeiro - 01", 2], ["RU Gama - 01", 2]]</tt>. Vazio quando não há agrupamento.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def totais
    case agrupar
    when "restaurante" then contar_por("restaurantes.nome").to_a
    when "catraca" then totais_por_catraca
    else []
    end
  end

  # Total de acessos de cada restaurante, inclusive os que não têm nenhum, do mais movimentado para o menos
  # movimentado. Ignora os filtros: é o resumo do Relatório Global de Operação (features/pdf_relatorio.feature).
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   +Array+ de pares <tt>[nome do restaurante, total]</tt>; empates ficam em ordem alfabética.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def totais_por_restaurante
    Restaurante.left_joins(catracas: :acessos).group(:id, :nome).count("acessos.id")
               .map { |(_id, nome), total| [ nome, total ] }
               .sort_by { |nome, total| [ -total, nome ] }
  end

  private

  # Quantidade de acessos filtrados em cada catraca, identificada junto com o restaurante.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   +Array+ de pares <tt>[grupo, total]</tt> ordenados por restaurante e catraca, ex.:
  #   <tt>[["RU Darcy Ribeiro - 01", 2], ["RU Darcy Ribeiro - 02", 1]]</tt>.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def totais_por_catraca
    contar_por("restaurantes.nome", "catracas.identificador").map do |(nome, identificador), total|
      [ "#{nome} - #{identificador}", total ]
    end
  end

  # Conta os acessos filtrados agrupando pelas colunas pedidas, em ordem crescente dessas colunas.
  #
  # Argumentos::
  #   - +colunas+: nomes das colunas do agrupamento, ex.: <tt>"restaurantes.nome"</tt>.
  # Retorno::
  #   +Hash+ do grupo para o total. Com uma coluna, a chave é o valor dela; com mais de uma, é um +Array+ com
  #   os valores na mesma ordem.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def contar_por(*colunas)
    filtrados.group(*colunas).order(*colunas).count
  end

  # Consulta dos acessos com os filtros de restaurante e catraca. Um restaurante inexistente não traz acesso
  # nenhum.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>ActiveRecord::Relation</tt> de Acesso, já com o +join+ em +catracas+ e +restaurantes+.
  # Efeitos colaterais:: nenhum.
  def filtrados
    relacao = Acesso.joins(catraca: :restaurante)
    return relacao.none if restaurante_id && restaurante.nil?

    if catraca
      relacao.where(catraca:)
    elsif restaurante
      relacao.where(catracas: { restaurante_id: restaurante.id })
    else
      relacao
    end
  end
end
