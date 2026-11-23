module PdfHistoricoEstudanteSteps
  # Linha de movimentação no texto do PDF, ex.: "Recarga · Cartão de crédito   12/10/2026 10:00   +R$ 20,00".
  LINHA_DE_MOVIMENTACAO = %r{\b(Recarga|Refeição)\b.*?(\d{2}/\d{2}/\d{4} \d{2}:\d{2})\s+([+-]R\$\s*[\d.,]+)}

  def documento_gerado?
    page.response_headers["Content-Type"].to_s.start_with?("application/pdf")
  end

  def texto_do_documento
    PDF::Reader.new(StringIO.new(page.source)).pages.map(&:text).join("\n")
  end

  # Movimentações do PDF no formato da tabela da feature: "+R$ 20,00" vira "20,00" e "-R$ 4,50" vira "-4,50".
  def movimentacoes_no_documento
    texto_do_documento.scan(LINHA_DE_MOVIMENTACAO).map do |tipo, data_hora, valor|
      [ tipo.downcase, valor.gsub(/[R$+\s]/, ""), data_hora ]
    end
  end
end
World(PdfHistoricoEstudanteSteps)

Quando("(eu )exporto meu extrato") do
  visit extrato_path
  click_link "Exportar PDF"
end

Quando("(eu )tento exportar meu extrato") do
  visit extrato_pdf_path
end

Então("(eu )devo ver as seguintes movimentações no documento, nesta ordem:") do |tabela|
  expect(documento_gerado?).to be(true)
  tabela.diff!([ %w[ tipo valor data_hora ], *movimentacoes_no_documento ])
end

Então("nenhum documento deve ser gerado") do
  expect(documento_gerado?).to be(false)
end
