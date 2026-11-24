require "rails_helper"

RSpec.describe DocumentoPdf do
  # Documento mínimo: o conteúdo é uma sequência de parágrafos, para dar o número de páginas que o teste quiser.
  let(:documento_de_teste) do
    Class.new(DocumentoPdf) do
      def initialize(paragrafos:, **)
        @paragrafos = paragrafos
        super(**)
      end

      private

      def titulo
        "Documento de teste"
      end

      def conteudo
        @paragrafos.times { |i| pdf.text "Parágrafo #{i + 1}" }
      end
    end
  end

  # Linhas de texto de cada página, sem linhas vazias e sem os espaços usados para alinhar.
  def paginas(paragrafos:)
    pdf = documento_de_teste.new(paragrafos:, gerado_em: Time.zone.local(2026, 11, 23, 15, 0)).render
    PDF::Reader.new(StringIO.new(pdf)).pages.map { |pagina| pagina.text.lines.map(&:squish).reject(&:empty?) }
  end

  describe "cabeçalho" do
    it "mostra a marca do RU e o título do documento antes do conteúdo" do
      expect(paginas(paragrafos: 1).first.first(3)).to eq([ "RU UnB · Restaurante Universitário", "Documento de teste", "Parágrafo 1" ])
    end

    it "aparece só na primeira página" do
      segunda_pagina = paginas(paragrafos: 80).second

      expect(segunda_pagina).not_to include("RU UnB · Restaurante Universitário", "Documento de teste")
    end
  end

  describe "rodapé" do
    it "mostra a data de geração e a numeração em todas as páginas" do
      rodapes = paginas(paragrafos: 80).map(&:last)

      expect(rodapes).to eq([
        "Gerado em 23/11/2026 15:00 Página 1 de 2",
        "Gerado em 23/11/2026 15:00 Página 2 de 2"
      ])
    end
  end
end
