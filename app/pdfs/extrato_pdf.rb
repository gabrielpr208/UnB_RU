# PDF do extrato do estudante (features/pdf_historico_estudante.feature): as mesmas movimentações e o mesmo
# formato da tela do extrato, inclusive os filtros aplicados, com o resumo de entradas e saídas.
class ExtratoPdf < DocumentoPdf
  def initialize(extrato, **)
    @extrato = extrato
    super(**)
  end

  private

  attr_reader :extrato

  def titulo
    "Extrato e histórico de refeições"
  end

  def estudante
    extrato.estudante
  end

  def conteudo
    dados(
      "Estudante" => estudante.nome,
      "Matrícula" => estudante.matricula,
      "Saldo atual" => reais(estudante.saldo),
      "Movimentações" => descricao_dos_filtros
    )

    subtitulo "Movimentações"
    tabela([ [ "MOVIMENTAÇÃO", "DATA E HORA", "VALOR" ], *linhas ], larguras: [ 250, 130, nil ], alinhar_a_direita: [ 2 ])

    subtitulo "Resumo"
    dados(
      "Entradas" => reais_com_sinal(extrato.entradas),
      "Saídas" => reais_com_sinal(extrato.saidas),
      "Quantidade de movimentações" => extrato.movimentacoes.size
    )
  end

  def linhas
    extrato.movimentacoes.map do |movimentacao|
      [ descricao(movimentacao), data_e_hora(movimentacao.data_hora), reais_com_sinal(movimentacao.valor) ]
    end
  end

  def descricao(movimentacao)
    return "Refeição" if movimentacao.refeicao?

    [ "Recarga", movimentacao.detalhe ].compact.join(" · ")
  end

  def descricao_dos_filtros
    return "todas" unless extrato.filtrado?

    partes = []
    partes << { "recargas" => "só recargas", "refeicoes" => "só refeições" }[extrato.tipo]
    partes << "a partir de #{data(extrato.data_inicial)}" if extrato.data_inicial
    partes << "até #{data(extrato.data_final)}" if extrato.data_final
    partes << "valor mínimo de #{reais(ValorMonetario.new.cast(extrato.valor_minimo))}" if extrato.valor_minimo.present?
    partes << "valor máximo de #{reais(ValorMonetario.new.cast(extrato.valor_maximo))}" if extrato.valor_maximo.present?
    "filtradas (#{partes.compact.join(', ')})"
  end
end
