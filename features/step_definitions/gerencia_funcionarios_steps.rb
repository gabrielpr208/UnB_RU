module GerenciaFuncionariosSteps
  # Linha da lista de funcionários cuja coluna Nome começa com `nome` (a linha do administrador logado tem o selo "Você").
  def linha_do_funcionario(nome)
    visit controle_funcionarios_path
    all("#funcionarios tbody tr").find { |linha| linha.find("td:first-child").text.start_with?(nome) } ||
      raise("Funcionário #{nome} não está na lista")
  end

  def editar_funcionario(nome)
    linha_do_funcionario(nome).click_link("Editar")
    yield
    click_button "Salvar alterações"
  end

  def nome_na_lista(siape)
    visit controle_funcionarios_path
    find("#funcionarios td", text: siape, exact_text: true).ancestor("tr").find("td:first-child").text.strip
  end

  def consegue_entrar?(siape, senha)
    click_button "Sair"
    fazer_login_de_funcionario("SIAPE" => siape, "senha" => senha)
    page.has_current_path?(controle_path)
  end
end
World(GerenciaFuncionariosSteps)

Dado("que existem os seguintes funcionários:") do |tabela|
  tabela.hashes.each do |linha|
    usuario = Usuario.create!(nome: linha["nome"], email: linha["email"], senha: AutenticacaoSteps::SENHA_PADRAO)
    Funcionario.create!(usuario:, siape: linha["siape"], administrador: linha["perfil"] == "Administrador")
  end
end

Dado("que o funcionário {string} está operando a catraca {string} do {string}") do |nome, identificador, restaurante|
  catraca = restaurante_chamado(restaurante).catracas.find_or_create_by!(identificador:)
  funcionario = Funcionario.joins(:usuario).find_by!(usuarios: { nome: })
  PontoAcesso.abrir!(funcionario:, catraca:)
end

Quando("eu altero o nome do funcionário {string} para {string}") do |nome, novo_nome|
  editar_funcionario(nome) { fill_in "Nome completo", with: novo_nome }
end

Quando("eu altero o perfil do funcionário {string} para {string}") do |nome, perfil|
  editar_funcionario(nome) { choose perfil }
end

Quando("eu altero a senha do funcionário {string} para {string}") do |nome, senha|
  editar_funcionario(nome) do
    fill_in "Nova senha", with: senha
    fill_in "Confirmação da nova senha", with: senha
  end
end

Quando("eu altero o funcionário {string} com {string} igual a {string}") do |nome, campo, valor|
  @funcionario_editado = Funcionario.joins(:usuario).find_by!(usuarios: { nome: })
  @dados_antes_da_edicao = @funcionario_editado.attributes.merge(@funcionario_editado.usuario.attributes)
  editar_funcionario(nome) { fill_in campo, with: valor }
end

Quando("eu removo o funcionário {string}") do |nome|
  linha_do_funcionario(nome).click_button("Remover")
end

Então("o funcionário com SIAPE {string} deve aparecer na lista com o nome {string}") do |siape, nome|
  expect(nome_na_lista(siape)).to eq(nome)
end

Então("o funcionário com SIAPE {string} deve conseguir entrar com a senha {string}") do |siape, senha|
  expect(consegue_entrar?(siape, senha)).to be(true)
end

Então("o funcionário com SIAPE {string} não deve conseguir entrar com a senha {string}") do |siape, senha|
  expect(consegue_entrar?(siape, senha)).to be(false)
  page.assert_text(Autenticacao::MENSAGEM_DE_ERRO_NO_LOGIN)
end

Então("o funcionário com SIAPE {string} deve continuar com os mesmos dados") do |siape|
  funcionario = Funcionario.find(@funcionario_editado.id)
  expect(funcionario.attributes.merge(funcionario.usuario.attributes)).to eq(@dados_antes_da_edicao)
  expect(funcionario.siape).to eq(siape)
end

Então("o funcionário {string} não deve aparecer na lista de funcionários") do |nome|
  visit controle_funcionarios_path
  expect(all("#funcionarios tbody tr td:first-child").map(&:text)).not_to include(nome)
end

Então("a catraca {string} do {string} deve estar livre") do |identificador, restaurante|
  visit controle_catracas_path
  expect(linha_da_catraca(identificador, restaurante).find("td:nth-child(3)").text).to eq("Livre")
end

Então("(eu )não devo ter a opção de remover o funcionário {string}") do |nome|
  expect(linha_do_funcionario(nome)).to have_no_button("Remover")
end

Então("(eu )devo ter a opção de remover o funcionário {string}") do |nome|
  expect(linha_do_funcionario(nome)).to have_button("Remover")
end
