module GerenciaCatracasSteps
  # Campus de cada restaurante usado nas features; nome sem campus conhecido vai para o Darcy Ribeiro.
  CAMPUS_DO_RESTAURANTE = { "RU Gama" => "Gama", "RU FCE" => "Ceilândia", "FUP" => "Planaltina" }.freeze

  def restaurante_chamado(nome)
    Restaurante.find_or_create_by!(nome:) do |restaurante|
      restaurante.campus = CAMPUS_DO_RESTAURANTE.fetch(nome, "Darcy Ribeiro")
    end
  end

  # Linha da lista de catracas com o restaurante e o identificador pedidos.
  def linha_da_catraca(identificador, restaurante)
    all("#catracas tbody tr").find do |linha|
      linha.all("td").first(2).map(&:text) == [ restaurante, identificador ]
    end || raise("Catraca #{identificador} do #{restaurante} não está na lista")
  end

  def preencher_catraca(identificador:, restaurante: nil)
    select restaurante.presence || "Selecione o restaurante", from: "Restaurante" unless restaurante.nil?
    fill_in "Identificador", with: identificador
  end

  # Tenta escolher a catraca como ponto de acesso, como faria um funcionário na Aplicação de Controle.
  def tentar_selecionar_catraca(identificador, restaurante)
    configurar_ponto_acesso("restaurante" => restaurante, "número da catraca" => identificador)
  end
end
World(GerenciaCatracasSteps)

Dado("que o restaurante {string} possui as catracas {string} e {string}") do |nome, primeira, segunda|
  restaurante = restaurante_chamado(nome)
  [ primeira, segunda ].each { |identificador| restaurante.catracas.create!(identificador:) }
end

Dado("que o restaurante {string} não possui catracas") do |nome|
  expect(restaurante_chamado(nome).catracas).to be_empty
  @quantidade_de_catracas = Catraca.count
end

Dado("que um funcionário selecionou a catraca {string} do {string} na Aplicação de Controle") do |identificador, nome|
  outro = criar_funcionario_com_login(siape: "1112223", senha: AutenticacaoSteps::SENHA_PADRAO, nome: "Carlos Dias")
  catraca = Restaurante.find_by!(nome:).catracas.find_by!(identificador:)
  PontoAcesso.abrir!(funcionario: outro, catraca:)
end

Quando("eu cadastro a catraca {string} no restaurante {string}") do |identificador, restaurante|
  @quantidade_de_catracas = Catraca.count
  visit controle_catracas_path
  click_link "Nova catraca"
  preencher_catraca(identificador:, restaurante:)
  click_button "Cadastrar catraca"
end

Quando("eu altero o identificador da catraca {string} do {string} para {string}") do |identificador, restaurante, novo|
  @restaurante_da_catraca = restaurante
  visit controle_catracas_path
  linha_da_catraca(identificador, restaurante).click_link("Editar")
  preencher_catraca(identificador: novo)
  click_button "Salvar alterações"
end

Quando("eu removo a catraca {string} do {string}") do |identificador, restaurante|
  @restaurante_da_catraca = restaurante
  visit controle_catracas_path
  linha_da_catraca(identificador, restaurante).click_button("Remover")
end

Então("a catraca {string} deve estar disponível para seleção na Aplicação de Controle do {string}") do |identificador, restaurante|
  tentar_selecionar_catraca(identificador, restaurante)
  page.assert_text("Configuração do ponto de acesso bem-sucedida")
end

Então("a catraca {string} não deve estar disponível para seleção na Aplicação de Controle do {string}") do |identificador, restaurante|
  tentar_selecionar_catraca(identificador, restaurante)
  page.assert_text("Catraca não encontrada neste restaurante")
end

Então("a catraca não deve ser cadastrada") do
  expect(Catraca.count).to eq(@quantidade_de_catracas)
end

Então("a catraca {string} deve continuar com o mesmo identificador") do |identificador|
  expect(Restaurante.find_by!(nome: @restaurante_da_catraca).catracas.exists?(identificador:)).to be(true)
end

Então("a catraca {string} deve continuar cadastrada") do |identificador|
  expect(Restaurante.find_by!(nome: @restaurante_da_catraca).catracas.exists?(identificador:)).to be(true)
  visit controle_catracas_path
  linha_da_catraca(identificador, @restaurante_da_catraca)
end
