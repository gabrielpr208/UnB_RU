# Histórico de todos os acessos dos restaurantes, para o administrador (features/relatorio_global.feature).
#
# Filtros opcionais: restaurante e, dentro dele, uma catraca. A catraca só vale junto com o restaurante
# dela; uma catraca de outro restaurante (ex.: o restaurante foi trocado no formulário) é ignorada.
#
# O agrupamento conta os acessos filtrados por restaurante ou por catraca.
class RelatorioAcessos
  include ActiveModel::Model
  include ActiveModel::Attributes

  AGRUPAMENTOS = %w[ restaurante catraca ].freeze

  attribute :restaurante_id, :integer
  attribute :catraca_id, :integer
  attribute :agrupar, :string

  # Um agrupamento desconhecido (ex.: alterado na URL) mostra a lista sem totais.
  def agrupar=(valor)
    super(AGRUPAMENTOS.include?(valor) ? valor : nil)
  end

  def restaurante
    return @restaurante if defined?(@restaurante)

    @restaurante = (Restaurante.find_by(id: restaurante_id) if restaurante_id)
  end

  def catraca
    return @catraca if defined?(@catraca)

    @catraca = (restaurante.catracas.find_by(id: catraca_id) if restaurante && catraca_id)
  end

  # Catracas que podem ser escolhidas no filtro: só as do restaurante selecionado.
  def catracas_disponiveis
    restaurante ? restaurante.catracas.order(:identificador) : Catraca.none
  end

  def filtrado?
    restaurante_id.present?
  end

  def acessos
    @acessos ||= filtrados.includes(:estudante, catraca: :restaurante).order(data_hora: :desc, id: :desc).to_a
  end

  # Pares [grupo, total] em ordem alfabética, ex.: [["RU Darcy Ribeiro - 01", 2], ["RU Gama - 01", 2]].
  def totais
    case agrupar
    when "restaurante"
      filtrados.group("restaurantes.nome").order("restaurantes.nome").count.to_a
    when "catraca"
      filtrados.group("restaurantes.nome", "catracas.identificador").order("restaurantes.nome", "catracas.identificador")
               .count.map { |(nome, identificador), total| [ "#{nome} - #{identificador}", total ] }
    else
      []
    end
  end

  # Total de acessos de cada restaurante, inclusive os que não têm nenhum, do mais movimentado para o menos
  # movimentado. Ignora os filtros: é o resumo do Relatório Global de Operação (features/pdf_relatorio.feature).
  def totais_por_restaurante
    Restaurante.left_joins(catracas: :acessos).group(:id, :nome).count("acessos.id")
               .map { |(_id, nome), total| [ nome, total ] }
               .sort_by { |nome, total| [ -total, nome ] }
  end

  private

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
