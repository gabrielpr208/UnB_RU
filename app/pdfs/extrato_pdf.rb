# PDF do extrato do estudante (features/pdf_historico_estudante.feature): as mesmas movimentações e o mesmo
# formato da tela do extrato, inclusive os filtros aplicados, com o resumo de entradas e saídas.
class ExtratoPdf < DocumentoPdf
  DESCRICAO_DO_TIPO = { "recargas" => "só recargas", "refeicoes" => "só refeições" }.freeze

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
    dados_do_estudante
    tabela_de_movimentacoes
    resumo
  end

  def dados_do_estudante
    dados(
      "Estudante" => estudante.nome,
      "Matrícula" => estudante.matricula,
      "Saldo atual" => reais(estudante.saldo),
      "Movimentações" => descricao_dos_filtros
    )
  end

  def tabela_de_movimentacoes
    subtitulo "Movimentações"
    tabela([ [ "MOVIMENTAÇÃO", "DATA E HORA", "VALOR" ], *linhas ], larguras: [ 250, 130, nil ], alinhar_a_direita: [ 2 ])
  end

  def resumo
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

    partes = [ DESCRICAO_DO_TIPO[extrato.tipo], *descricao_do_periodo, *descricao_da_faixa_de_valor ]
    "filtradas (#{partes.compact.join(', ')})"
  end

  def descricao_do_periodo
    partes = []
    partes << "a partir de #{data(extrato.data_inicial)}" if extrato.data_inicial
    partes << "até #{data(extrato.data_final)}" if extrato.data_final
    partes
  end

  # O controller só gera o PDF com filtros válidos, então minimo e maximo só são nil quando estão em branco.
  def descricao_da_faixa_de_valor
    partes = []
    partes << "valor mínimo de #{reais(extrato.minimo)}" if extrato.minimo
    partes << "valor máximo de #{reais(extrato.maximo)}" if extrato.maximo
    partes
  end
end
