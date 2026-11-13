module GerenciaRestaurantesSteps
  # Linha da tabela da lista de restaurantes cuja coluna Nome é exatamente `nome`.
  def linha_do_restaurante(nome)
    find("#restaurantes td", text: nome, exact_text: true).ancestor("tr")
  end

  def nomes_na_lista
    visit controle_restaurantes_path
    all("#restaurantes tbody tr td:first-child").map(&:text)
  end

  def preencher_restaurante(nome:, campus: nil)
    fill_in "Nome", with: nome
    fill_in "Campus", with: campus unless campus.nil?
  end
end
World(GerenciaRestaurantesSteps)

Dado("que existem os seguintes restaurantes:") do |tabela|
  tabela.hashes.each { |linha| Restaurante.create!(nome: linha["nome"], campus: linha["campus"]) }
  @quantidade_de_restaurantes = Restaurante.count
end

Dado("que o restaurante {string} possui a catraca {string}") do |nome, identificador|
  Restaurante.find_by!(nome:).catracas.create!(identificador:)
end

Quando("eu cadastro o restaurante {string} no campus {string}") do |nome, campus|
  visit controle_restaurantes_path
  click_link "Novo restaurante"
  preencher_restaurante(nome:, campus:)
  click_button "Cadastrar restaurante"
end

Quando("eu altero o nome do restaurante {string} para {string}") do |nome_atual, novo_nome|
  visit controle_restaurantes_path
  linha_do_restaurante(nome_atual).click_link("Editar")
  preencher_restaurante(nome: novo_nome)
  click_button "Salvar alterações"
end

Quando("eu removo o restaurante {string}") do |nome|
  visit controle_restaurantes_path
  linha_do_restaurante(nome).click_button("Remover")
end

Então("o restaurante {string} deve aparecer na lista de restaurantes") do |nome|
  expect(nomes_na_lista).to include(nome)
end

Então("o restaurante {string} não deve aparecer na lista de restaurantes") do |nome|
  expect(nomes_na_lista).not_to include(nome)
end

Então("o restaurante não deve ser cadastrado") do
  expect(Restaurante.count).to eq(@quantidade_de_restaurantes)
end

Então("o restaurante {string} deve continuar com o mesmo nome") do |nome|
  expect(Restaurante.exists?(nome:)).to be(true)
  expect(nomes_na_lista).to include(nome)
end
