# Base dos PDFs exportados pelo sistema (extrato do estudante e, depois, o relatório de operação).
#
# Cuida do que todo documento tem em comum: cabeçalho com a marca e o título, tabela no estilo das telas,
# rodapé com a data de geração e a numeração das páginas. Cada documento implementa `conteudo`.
#
# Usa a fonte Helvetica embutida no próprio formato PDF, que cobre os acentos do português.
class DocumentoPdf
  include ActionView::Helpers::NumberHelper

  COR_PRIMARIA = "003366".freeze
  COR_TEXTO_SUAVE = "5F6368".freeze
  COR_BORDA = "DADCE0".freeze
  COR_ENTRADA = "1E7B34".freeze

  def initialize(gerado_em: Time.current)
    @gerado_em = gerado_em
    @pdf = Prawn::Document.new(page_size: "A4", margin: [ 48, 48, 60, 48 ], info: { Title: titulo, Creator: "RU UnB" })
  end

  def render
    cabecalho
    conteudo
    rodape
    @pdf.render
  end

  private

  attr_reader :pdf, :gerado_em

  def titulo
    raise NotImplementedError
  end

  def conteudo
    raise NotImplementedError
  end

  def cabecalho
    pdf.fill_color COR_PRIMARIA
    pdf.text "RU UnB · Restaurante Universitário", size: 10, style: :bold
    pdf.fill_color "000000"
    pdf.move_down 4
    pdf.text titulo, size: 20, style: :bold
    pdf.move_down 6
    pdf.stroke_color COR_BORDA
    pdf.stroke_horizontal_rule
    pdf.move_down 16
  end

  # Lista de rótulo e valor, como a `lista-dados` das telas (ex.: Estudante: Maria Souza).
  def dados(pares)
    pares.each do |rotulo, valor|
      pdf.formatted_text [ { text: "#{rotulo}: ", styles: [ :bold ] }, { text: valor.to_s } ], size: 10
      pdf.move_down 2
    end
    pdf.move_down 12
  end

  def subtitulo(texto)
    pdf.text texto, size: 13, style: :bold
    pdf.move_down 8
  end

  # Tabela com a primeira linha como cabeçalho. `alinhar_a_direita` lista os índices das colunas numéricas.
  def tabela(linhas, larguras:, alinhar_a_direita: [])
    pdf.table(linhas, header: true, width: pdf.bounds.width, column_widths: larguras,
                      cell_style: { size: 10, padding: [ 6, 6 ], borders: [ :bottom ], border_color: COR_BORDA }) do |t|
      t.row(0).font_style = :bold
      t.row(0).text_color = COR_TEXTO_SUAVE
      t.row(0).size = 8
      alinhar_a_direita.each { |coluna| t.column(coluna).align = :right }
    end
    pdf.move_down 16
  end

  def rodape
    pdf.repeat(:all) do
      pdf.bounding_box([ pdf.bounds.left, pdf.bounds.bottom - 20 ], width: pdf.bounds.width, height: 20) do
        pdf.fill_color COR_TEXTO_SUAVE
        pdf.text "Gerado em #{data_e_hora(gerado_em)}", size: 8
        pdf.fill_color "000000"
      end
    end
    pdf.number_pages "Página <page> de <total>", at: [ pdf.bounds.right - 120, pdf.bounds.bottom - 20 ],
                                                 width: 120, align: :right, size: 8, color: COR_TEXTO_SUAVE
  end

  def reais(valor)
    ValorMonetario.formatar(valor)
  end

  # Mesmo formato do extrato na tela: "+R$ 20,00" para entradas e "-R$ 4,50" para saídas.
  def reais_com_sinal(valor)
    sinal = if valor.positive? then "+" elsif valor.negative? then "-" end
    "#{sinal}#{reais(valor.abs)}"
  end

  def data_e_hora(tempo)
    tempo.in_time_zone.strftime("%d/%m/%Y %H:%M")
  end

  def data(dia)
    dia.strftime("%d/%m/%Y")
  end
end
