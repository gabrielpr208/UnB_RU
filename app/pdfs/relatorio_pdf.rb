# PDF do Relatório Global de Operação (features/pdf_relatorio.feature): o total de acessos de cada restaurante,
# inclusive os sem acessos, com o total geral, e todos os acessos, do mais recente para o mais antigo.
class RelatorioPdf < DocumentoPdf
  # Prepara o PDF do relatório.
  #
  # Argumentos::
  #   - +relatorio+: RelatorioAcessos com os acessos listados (padrão: todos, sem filtros).
  #   - demais opções de DocumentoPdf.new (ex.: +gerado_em+).
  # Retorno:: o documento, pronto para #render.
  # Efeitos colaterais:: nenhum.
  def initialize(relatorio = RelatorioAcessos.new, **)
    @relatorio = relatorio
    super(**)
  end

  private

  # Relatório exportado.
  attr_reader :relatorio

  # Título do documento.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>"Relatório Global de Operação"</tt>.
  # Efeitos colaterais:: nenhum.
  def titulo
    "Relatório Global de Operação"
  end

  # Desenha a tabela de totais por restaurante e a lista de acessos.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def conteudo
    tabela_de_totais
    tabela_de_acessos
  end

  # Desenha a seção de totais: o total de acessos de cada restaurante (ver RelatorioAcessos#totais_por_restaurante)
  # e, na última linha, o total geral.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def tabela_de_totais
    totais = relatorio.totais_por_restaurante

    subtitulo "Totais por restaurante"
    tabela([ [ "RESTAURANTE", "ACESSOS" ], *totais.map { |nome, total| [ nome, total.to_s ] },
             [ "Total geral", totais.sum(&:last).to_s ] ],
           larguras: [ 380, nil ], alinhar_a_direita: [ 1 ])
  end

  # Desenha a seção de acessos, com uma linha por acesso (ver #linhas), ou um aviso quando não há nenhum.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def tabela_de_acessos
    subtitulo "Acessos"
    if relatorio.acessos.empty?
      pdf.text "Nenhum acesso registrado.", size: 10, color: COR_TEXTO_SUAVE
    else
      tabela([ [ "ESTUDANTE", "RESTAURANTE", "CATRACA", "DATA E HORA" ], *linhas ], larguras: [ 110, 200, 70, nil ])
    end
  end

  # Linhas da tabela de acessos.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Array+ com uma linha por acesso: matrícula, restaurante, catraca e data e hora.
  # Efeitos colaterais:: nenhum.
  def linhas
    relatorio.acessos.map do |acesso|
      [ acesso.estudante.matricula, acesso.catraca.restaurante.nome, acesso.catraca.identificador,
        data_e_hora(acesso.data_hora) ]
    end
  end
end
