module CadastroFuncionarioSteps
  # Rótulos dos campos do formulário com valores válidos.
  DADOS_VALIDOS = {
    "Nome completo" => "Carlos Dias",
    "SIAPE" => "1112223",
    "E-mail" => "carlos@unb.br",
    "Senha" => "senha123",
    "Confirmação de senha" => "senha123"
  }.freeze

  def cadastrar_funcionario(dados, perfil: nil)
    @total_usuarios_antes = Usuario.count
    @total_funcionarios_antes = Funcionario.count

    visit controle_funcionarios_path
    click_link "Novo funcionário"
    dados.each { |rotulo, valor| fill_in rotulo, with: valor }
    choose perfil if perfil
    click_button "Cadastrar funcionário"
  end

  def perfil_na_lista(siape)
    visit controle_funcionarios_path
    find("#funcionarios td", text: siape, exact_text: true).ancestor("tr").find("td:nth-child(4)").text.strip
  end
end
World(CadastroFuncionarioSteps)

Quando("eu cadastro o funcionário {string} com SIAPE {string} e perfil {string}") do |nome, siape, perfil|
  cadastrar_funcionario(CadastroFuncionarioSteps::DADOS_VALIDOS.merge("Nome completo" => nome, "SIAPE" => siape), perfil:)
end

Quando("eu cadastro um funcionário com {string} igual a {string} e os demais dados válidos") do |campo, valor|
  cadastrar_funcionario(CadastroFuncionarioSteps::DADOS_VALIDOS.merge(campo => valor))
end

Quando("eu tento acessar o cadastro de funcionários") do
  visit new_controle_funcionario_path
end

Então("o funcionário com SIAPE {string} deve aparecer na lista com o perfil {string}") do |siape, perfil|
  expect(perfil_na_lista(siape)).to eq(perfil)
end

Então("o funcionário não deve ser cadastrado") do
  expect(Usuario.count).to eq(@total_usuarios_antes)
  expect(Funcionario.count).to eq(@total_funcionarios_antes)
end
