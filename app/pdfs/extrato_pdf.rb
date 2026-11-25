# PDF do extrato do estudante (features/pdf_historico_estudante.feature): as mesmas movimentações e o mesmo
# formato da tela do extrato, inclusive os filtros aplicados, com o resumo de entradas e saídas.
class ExtratoPdf < DocumentoPdf
  # Texto do filtro de tipo na descrição dos filtros. O tipo <tt>"todos"</tt> não aparece.
  DESCRICAO_DO_TIPO = { "recargas" => "só recargas", "refeicoes" => "só refeições" }.freeze

  # Prepara o PDF de um extrato.
  #
  # Argumentos::
  #   - +extrato+: Extrato, já com o estudante e os filtros.
  #   - demais opções de DocumentoPdf.new (ex.: +gerado_em+).
  # Retorno:: o documento, pronto para #render.
  # Efeitos colaterais:: nenhum.
  def initialize(extrato, **)
    @extrato = extrato
    super(**)
  end

  private

  # Extrato exportado.
  attr_reader :extrato

  # Título do documento.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>"Extrato e histórico de refeições"</tt>.
  # Efeitos colaterais:: nenhum.
  def titulo
    "Extrato e histórico de refeições"
  end

  # Estudante dono do extrato.
  #
  # Argumentos:: nenhum.
  # Retorno:: o Estudante.
  # Efeitos colaterais:: nenhum.
  def estudante
    extrato.estudante
  end

  # Desenha os dados do estudante, a tabela de movimentações e o resumo de entradas e saídas.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def conteudo
    dados_do_estudante
    tabela_de_movimentacoes
    resumo
  end

  # Desenha o nome, a matrícula e o saldo do estudante e quais movimentações o documento inclui
  # (ver #descricao_dos_filtros).
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def dados_do_estudante
    dados(
      "Estudante" => estudante.nome,
      "Matrícula" => estudante.matricula,
      "Saldo atual" => reais(estudante.saldo),
      "Movimentações" => descricao_dos_filtros
    )
  end

  # Desenha a seção de movimentações, com uma linha por movimentação (ver #linhas).
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def tabela_de_movimentacoes
    subtitulo "Movimentações"
    tabela([ [ "MOVIMENTAÇÃO", "DATA E HORA", "VALOR" ], *linhas ], larguras: [ 250, 130, nil ], alinhar_a_direita: [ 2 ])
  end

  # Desenha a seção de resumo: total de entradas, total de saídas e quantidade de movimentações.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def resumo
    subtitulo "Resumo"
    dados(
      "Entradas" => reais_com_sinal(extrato.entradas),
      "Saídas" => reais_com_sinal(extrato.saidas),
      "Quantidade de movimentações" => extrato.movimentacoes.size
    )
  end

  # Linhas da tabela de movimentações.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Array+ com uma linha por movimentação: descrição, data e hora e valor com sinal.
  # Efeitos colaterais:: nenhum.
  def linhas
    extrato.movimentacoes.map do |movimentacao|
      [ descricao(movimentacao), data_e_hora(movimentacao.data_hora), reais_com_sinal(movimentacao.valor) ]
    end
  end

  # Descrição de uma movimentação na tabela.
  #
  # Argumentos::
  #   - +movimentacao+: Movimentacao do extrato.
  # Retorno::
  #   +String+: <tt>"Refeição"</tt> ou a recarga com a forma de pagamento (ex.: <tt>"Recarga · PIX"</tt>).
  # Efeitos colaterais:: nenhum.
  def descricao(movimentacao)
    return "Refeição" if movimentacao.refeicao?

    [ "Recarga", movimentacao.detalhe ].compact.join(" · ")
  end

  # Resumo dos filtros aplicados ao extrato, para o leitor saber o que o documento inclui.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - <tt>"todas"</tt> sem filtros;
  #   - os filtros aplicados, ex.: <tt>"filtradas (só refeições, a partir de 01/03/2026)"</tt>.
  # Efeitos colaterais:: nenhum.
  def descricao_dos_filtros
    return "todas" unless extrato.filtrado?

    partes = [ DESCRICAO_DO_TIPO[extrato.tipo], *descricao_do_periodo, *descricao_da_faixa_de_valor ]
    "filtradas (#{partes.compact.join(', ')})"
  end

  # Partes da descrição dos filtros que falam do período.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   +Array+ de +String+ com a data inicial e a data final preenchidas (ex.: <tt>["a partir de 01/03/2026"]</tt>);
  #   vazio quando não há período.
  # Efeitos colaterais:: nenhum.
  def descricao_do_periodo
    partes = []
    partes << "a partir de #{data(extrato.data_inicial)}" if extrato.data_inicial
    partes << "até #{data(extrato.data_final)}" if extrato.data_final
    partes
  end

  # Partes da descrição dos filtros que falam da faixa de valor. O controller só gera o PDF com filtros válidos,
  # então Extrato#minimo e Extrato#maximo só são +nil+ quando estão em branco.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   +Array+ de +String+ com o valor mínimo e o valor máximo preenchidos
  #   (ex.: <tt>["valor mínimo de R$ 4,00"]</tt>); vazio quando não há faixa de valor.
  # Efeitos colaterais:: nenhum.
  def descricao_da_faixa_de_valor
    partes = []
    partes << "valor mínimo de #{reais(extrato.minimo)}" if extrato.minimo
    partes << "valor máximo de #{reais(extrato.maximo)}" if extrato.maximo
    partes
  end
end
