module PdfRelatorioSteps
  # Linha de acesso no texto do PDF, ex.: "231012345   RU Darcy Ribeiro   01   16/10/2026 12:30".
  LINHA_DE_ACESSO = %r{(\d{9})\s+(.+?)\s+(\d{2})\s+(\d{2}/\d{2}/\d{4} \d{2}:\d{2})}
  # Linha de total, ex.: "RU Darcy Ribeiro   3" ou "Total geral   5".
  LINHA_DE_TOTAL = /\A\s*(\S.*?)\s{2,}(\d+)\s*\z/

  # Texto do PDF dividido nas duas seções: os totais vêm antes do título "Acessos".
  def secoes_do_relatorio
    texto_do_documento.split(/^\s*Acessos\s*$/, 2)
  end

  def acessos_no_documento
    secoes_do_relatorio.last.scan(LINHA_DE_ACESSO).map { |linha| linha.map(&:strip) }
  end

  def totais_no_documento
    secoes_do_relatorio.first.lines.filter_map { |linha| linha.match(LINHA_DE_TOTAL)&.captures }
  end
end
World(PdfRelatorioSteps)

# "Administrador geral" é o mesmo perfil de administrador da gestão de restaurantes e catracas.
Dado("que (eu )estou logado como administrador geral") do
  @funcionario ||= criar_funcionario_com_login(siape: "7654321", nome: "Ana Lima", administrador: true)

  fazer_login_de_funcionario("SIAPE" => @funcionario.siape, "senha" => AutenticacaoSteps::SENHA_PADRAO)
  page.assert_current_path(controle_path)
end

Quando("(eu )exporto o relatório global de operação") do
  visit controle_relatorio_path
  click_link "Exportar relatório global (PDF)"
end

Quando("(eu )tento exportar o relatório global de operação") do
  visit controle_relatorio_pdf_path
end

Então("(eu )devo ver os seguintes acessos no documento, nesta ordem:") do |tabela|
  expect(documento_gerado?).to be(true)
  tabela.diff!([ %w[ estudante restaurante catraca data_hora ], *acessos_no_documento ])
end

Então("(eu )devo ver os seguintes totais no documento:") do |tabela|
  tabela.diff!([ %w[ restaurante total ], *totais_no_documento ])
end
