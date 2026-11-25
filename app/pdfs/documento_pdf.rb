# Base dos PDFs exportados pelo sistema (ExtratoPdf e RelatorioPdf).
#
# Cuida do que todo documento tem em comum: cabeçalho com a marca e o título, tabela no estilo das telas,
# rodapé com a data de geração e a numeração das páginas. Cada documento implementa +titulo+ e +conteudo+.
#
# Usa a fonte Helvetica embutida no próprio formato PDF, que cobre os acentos do português.
class DocumentoPdf
  include ActionView::Helpers::NumberHelper

  # Azul da marca, usado no nome do sistema no cabeçalho.
  COR_PRIMARIA = "003366".freeze
  # Cinza dos textos secundários (cabeçalho das tabelas e rodapé).
  COR_TEXTO_SUAVE = "5F6368".freeze
  # Cinza das linhas divisórias.
  COR_BORDA = "DADCE0".freeze
  # Verde das entradas de dinheiro.
  COR_ENTRADA = "1E7B34".freeze
  # Altura da faixa do rodapé, em pontos. A faixa começa essa mesma distância abaixo da margem inferior.
  ALTURA_DO_RODAPE = 20

  # Prepara um documento A4 em branco.
  #
  # Argumentos::
  #   - +gerado_em+: data e hora mostradas no rodapé (padrão: +Time.current+).
  # Retorno:: o documento, pronto para #render.
  # Efeitos colaterais:: nenhum.
  def initialize(gerado_em: Time.current)
    @gerado_em = gerado_em
    @pdf = Prawn::Document.new(page_size: "A4", margin: [ 48, 48, 60, 48 ], info: { Title: titulo, Creator: "RU UnB" })
  end

  # Desenha o cabeçalho, o conteúdo e o rodapé e gera o arquivo.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ binária com o conteúdo do arquivo PDF.
  # Efeitos colaterais:: nenhum (o arquivo não é gravado em disco).
  def render
    cabecalho
    conteudo
    rodape
    @pdf.render
  end

  private

  # Documento Prawn em que as páginas são desenhadas.
  attr_reader :pdf
  # Data e hora de geração, mostradas no rodapé.
  attr_reader :gerado_em

  # Título do documento, mostrado no cabeçalho e nas propriedades do arquivo. Cada subclasse define o seu.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com o título.
  # Efeitos colaterais:: levanta +NotImplementedError+ se a subclasse não o redefinir.
  def titulo
    raise NotImplementedError
  end

  # Desenha a parte específica do documento, entre o cabeçalho e o rodapé. Cada subclasse define a sua.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: levanta +NotImplementedError+ se a subclasse não o redefinir.
  def conteudo
    raise NotImplementedError
  end

  # Desenha o cabeçalho: nome do sistema, título do documento e uma linha divisória (ver #linha_divisoria).
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def cabecalho
    pdf.text "RU UnB · Restaurante Universitário", size: 10, style: :bold, color: COR_PRIMARIA
    pdf.move_down 4
    pdf.text titulo, size: 20, style: :bold
    pdf.move_down 6
    linha_divisoria
  end

  # Desenha uma linha horizontal na largura da página, com um espaço abaixo.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF; a cor das linhas do documento passa a ser COR_BORDA.
  def linha_divisoria
    pdf.stroke_color COR_BORDA
    pdf.stroke_horizontal_rule
    pdf.move_down 16
  end

  # Desenha uma lista de rótulo e valor, como a +lista-dados+ das telas (ex.: Estudante: Maria Souza).
  #
  # Argumentos::
  #   - +pares+: +Hash+ (ou lista de pares) de rótulo e valor.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF uma linha por par.
  def dados(pares)
    pares.each do |rotulo, valor|
      pdf.formatted_text [ { text: "#{rotulo}: ", styles: [ :bold ] }, { text: valor.to_s } ], size: 10
      pdf.move_down 2
    end
    pdf.move_down 12
  end

  # Desenha o título de uma seção do documento.
  #
  # Argumentos::
  #   - +texto+: título da seção.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def subtitulo(texto)
    pdf.text texto, size: 13, style: :bold
    pdf.move_down 8
  end

  # Desenha uma tabela com a primeira linha como cabeçalho, repetido a cada página.
  #
  # Argumentos::
  #   - +linhas+: +Array+ de linhas, cada uma um +Array+ de textos; a primeira é o cabeçalho.
  #   - +larguras+: largura de cada coluna, em pontos (+nil+ ocupa o espaço que sobra).
  #   - +alinhar_a_direita+: índices das colunas numéricas, alinhadas à direita (padrão: nenhuma).
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
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

  # Desenha o rodapé numa faixa logo abaixo da margem inferior, em todas as páginas: data de geração à esquerda
  # e numeração à direita.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF (ver #data_de_geracao e #numeracao_das_paginas).
  def rodape
    pdf.repeat(:all) { data_de_geracao }
    numeracao_das_paginas
  end

  # Escreve a data e hora de geração do documento à esquerda da faixa do rodapé.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha no PDF.
  def data_de_geracao
    pdf.bounding_box([ pdf.bounds.left, topo_do_rodape ], width: pdf.bounds.width, height: ALTURA_DO_RODAPE) do
      pdf.text "Gerado em #{data_e_hora(gerado_em)}", size: 8, color: COR_TEXTO_SUAVE
    end
  end

  # Numera as páginas à direita da faixa do rodapé (ex.: "Página 1 de 3").
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: desenha a numeração em todas as páginas do PDF.
  def numeracao_das_paginas
    pdf.number_pages "Página <page> de <total>", at: [ pdf.bounds.right - 120, topo_do_rodape ],
                                                 width: 120, align: :right, size: 8, color: COR_TEXTO_SUAVE
  end

  # Posição vertical do topo da faixa do rodapé: ALTURA_DO_RODAPE pontos abaixo da margem inferior.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Numeric+ com a coordenada vertical, em pontos.
  # Efeitos colaterais:: nenhum.
  def topo_do_rodape
    pdf.bounds.bottom - ALTURA_DO_RODAPE
  end

  # Formata um valor em reais (ver ValorMonetario.formatar).
  #
  # Argumentos::
  #   - +valor+: número a formatar.
  # Retorno:: +String+ como <tt>"R$ 20,00"</tt>.
  # Efeitos colaterais:: nenhum.
  def reais(valor)
    ValorMonetario.formatar(valor)
  end

  # Formata um valor em reais com sinal, no mesmo formato do extrato na tela.
  #
  # Argumentos::
  #   - +valor+: número a formatar, positivo para entradas e negativo para saídas.
  # Retorno::
  #   +String+ como <tt>"+R$ 20,00"</tt> para entradas, <tt>"-R$ 4,50"</tt> para saídas ou
  #   <tt>"R$ 0,00"</tt> para zero.
  # Efeitos colaterais:: nenhum.
  def reais_com_sinal(valor)
    sinal = if valor.positive? then "+" elsif valor.negative? then "-" end
    "#{sinal}#{reais(valor.abs)}"
  end

  # Formata data e hora no fuso do sistema.
  #
  # Argumentos::
  #   - +tempo+: data e hora a formatar.
  # Retorno:: +String+ no formato <tt>"DD/MM/AAAA HH:MM"</tt>.
  # Efeitos colaterais:: nenhum.
  def data_e_hora(tempo)
    tempo.in_time_zone.strftime("%d/%m/%Y %H:%M")
  end

  # Formata uma data.
  #
  # Argumentos::
  #   - +dia+: data a formatar.
  # Retorno:: +String+ no formato <tt>"DD/MM/AAAA"</tt>.
  # Efeitos colaterais:: nenhum.
  def data(dia)
    dia.strftime("%d/%m/%Y")
  end
end
