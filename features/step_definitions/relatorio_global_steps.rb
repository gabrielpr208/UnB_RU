module RelatorioGlobalSteps
  # Cria o estudante pela matrícula, se ainda não existir, sem login (só aparece no histórico).
  def estudante_com_matricula(matricula)
    Estudante.find_by(matricula:) || begin
      usuario = Usuario.create!(nome: "Estudante #{matricula}", email: "#{matricula}@aluno.unb.br",
                                senha: AutenticacaoSteps::SENHA_PADRAO)
      Estudante.create!(usuario:, matricula:)
    end
  end

  # Linhas da lista de acessos: [estudante, restaurante, catraca, data e hora].
  def acessos_na_tela
    all("#acessos tbody tr").map { |linha| linha.all("td").map(&:text) }
  end

  def filtrar_relatorio(restaurante: nil, catraca: nil)
    select restaurante, from: "Restaurante" if restaurante
    click_button "Filtrar"
    return unless catraca

    select catraca, from: "Catraca"
    click_button "Filtrar"
  end
end
World(RelatorioGlobalSteps)

Dado("que existe o restaurante {string} sem acessos registrados") do |nome|
  expect(Acesso.joins(:catraca).where(catracas: { restaurante: restaurante_chamado(nome) })).to be_empty
end

Dado("que foram registrados os seguintes acessos:") do |tabela|
  tabela.hashes.each do |linha|
    catraca = restaurante_chamado(linha["restaurante"]).catracas.find_or_create_by!(identificador: linha["catraca"])
    Acesso.create!(estudante: estudante_com_matricula(linha["estudante"]), catraca:, valor_cobrado: 4.50,
                   data_hora: Time.zone.strptime(linha["data_hora"], "%d/%m/%Y %H:%M"))
  end
end

Quando("eu acesso o histórico de acessos") do
  visit controle_relatorio_path
end

Quando("eu filtro o histórico pelo restaurante {string}") do |restaurante|
  visit controle_relatorio_path unless page.current_path == controle_relatorio_path
  filtrar_relatorio(restaurante:)
end

Quando("eu filtro o histórico pelo restaurante {string} e pela catraca {string}") do |restaurante, catraca|
  visit controle_relatorio_path
  filtrar_relatorio(restaurante:, catraca:)
end

# Sem JavaScript, trocar o restaurante e clicar em Filtrar é o que o formulário faz sozinho no navegador.
Quando("eu seleciono o restaurante {string} no filtro") do |restaurante|
  filtrar_relatorio(restaurante:)
end

Quando("eu agrupo o histórico por {word}") do |grupo|
  visit controle_relatorio_path unless page.current_path == controle_relatorio_path
  choose "Por #{grupo}"
  click_button "Filtrar"
end

Então("eu devo ver {int} acessos") do |quantidade|
  page.assert_selector("#acessos tbody tr", count: quantidade)
end

Então("cada acesso deve exibir estudante, restaurante, catraca e data\\/hora") do
  acessos_na_tela.each do |estudante, restaurante, catraca, data_hora|
    expect(estudante).to match(/\A\d{9}\z/)
    expect(restaurante).to be_present
    expect(catraca).to match(/\A\d{2}\z/)
    expect(data_hora).to match(%r{\A\d{2}/\d{2}/\d{4} \d{2}:\d{2}\z})
  end
end

Então("o primeiro acesso da lista deve ser o de {string}") do |data_hora|
  expect(acessos_na_tela.first.last).to eq(data_hora)
end

Então("o último acesso da lista deve ser o de {string}") do |data_hora|
  expect(acessos_na_tela.last.last).to eq(data_hora)
end

Então("todos os acessos exibidos devem ser do restaurante {string}") do |restaurante|
  expect(acessos_na_tela.map { |linha| linha[1] }.uniq).to eq([ restaurante ])
end

Então("todos os acessos exibidos devem ser da catraca {string} do {string}") do |catraca, restaurante|
  expect(acessos_na_tela.map { |linha| linha[1..2] }.uniq).to eq([ [ restaurante, catraca ] ])
end

Então("as opções de catraca devem ser apenas {string}") do |catraca|
  opcoes = find_field("Catraca").all("option").map(&:text) - [ "Todas as catracas" ]
  expect(opcoes).to eq([ catraca ])
end

Então("o filtro de catraca deve estar desabilitado") do
  expect(page).to have_field("Catraca", disabled: true)
end

Então("eu devo ver a dica {string}") do |dica|
  page.assert_selector(".campo__dica", text: dica)
end

Então("eu não devo ver nenhum acesso na lista") do
  page.assert_no_selector("#acessos tbody tr")
end

Então("eu devo ver os seguintes totais:") do |tabela|
  totais = all("#totais tbody tr").map { |linha| linha.all("td").map(&:text) }
  tabela.diff!([ %w[ grupo total ], *totais ])
end
