# PDF do Relatório Global de Operação (features/pdf_relatorio.feature): o total de acessos de cada restaurante,
# inclusive os sem acessos, com o total geral, e todos os acessos, do mais recente para o mais antigo.
class RelatorioPdf < DocumentoPdf
  def initialize(relatorio = RelatorioAcessos.new, **)
    @relatorio = relatorio
    super(**)
  end

  private

  attr_reader :relatorio

  def titulo
    "Relatório Global de Operação"
  end

  def conteudo
    totais = relatorio.totais_por_restaurante

    subtitulo "Totais por restaurante"
    tabela([ [ "RESTAURANTE", "ACESSOS" ], *totais.map { |nome, total| [ nome, total.to_s ] },
             [ "Total geral", totais.sum(&:last).to_s ] ],
           larguras: [ 380, nil ], alinhar_a_direita: [ 1 ])

    subtitulo "Acessos"
    if relatorio.acessos.empty?
      pdf.text "Nenhum acesso registrado.", size: 10, color: COR_TEXTO_SUAVE
    else
      tabela([ [ "ESTUDANTE", "RESTAURANTE", "CATRACA", "DATA E HORA" ], *linhas ], larguras: [ 110, 200, 70, nil ])
    end
  end

  def linhas
    relatorio.acessos.map do |acesso|
      [ acesso.estudante.matricula, acesso.catraca.restaurante.nome, acesso.catraca.identificador,
        data_e_hora(acesso.data_hora) ]
    end
  end
end
