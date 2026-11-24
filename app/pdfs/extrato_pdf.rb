# PDF do extrato do estudante (features/pdf_historico_estudante.feature): as mesmas movimentações e o mesmo
# formato da tela do extrato, inclusive os filtros aplicados, com o resumo de entradas e saídas.
class ExtratoPdf < DocumentoPdf
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

    partes = []
    partes << { "recargas" => "só recargas", "refeicoes" => "só refeições" }[extrato.tipo]
    partes << "a partir de #{data(extrato.data_inicial)}" if extrato.data_inicial
    partes << "até #{data(extrato.data_final)}" if extrato.data_final
    partes << "valor mínimo de #{reais(ValorMonetario.new.cast(extrato.valor_minimo))}" if extrato.valor_minimo.present?
    partes << "valor máximo de #{reais(ValorMonetario.new.cast(extrato.valor_maximo))}" if extrato.valor_maximo.present?
    "filtradas (#{partes.compact.join(', ')})"
  end
end
