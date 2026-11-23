module AutenticacaoSteps
  SENHA_PADRAO = "senha123".freeze

  def criar_estudante_com_login(nome: "Maria Souza", matricula: "231012345", senha: SENHA_PADRAO)
    usuario = Usuario.create!(nome:, email: "#{matricula}@aluno.unb.br", senha:)
    Estudante.create!(usuario:, matricula:)
  end

  def fazer_login(matricula, senha)
    fill_in "Matrícula", with: matricula
    fill_in "Senha", with: senha
    click_button "Entrar"
  end
end
World(AutenticacaoSteps)

Dado("que existe o estudante {string} com matrícula {string} e senha {string}") do |nome, matricula, senha|
  @estudante = criar_estudante_com_login(nome:, matricula:, senha:)
  @senha = senha
end

Dado("que (eu )estou logado como estudante") do
  @estudante ||= criar_estudante_com_login
  @senha ||= AutenticacaoSteps::SENHA_PADRAO

  visit login_path
  fazer_login(@estudante.matricula, @senha)
  page.assert_current_path(root_path)
end

Dado("que (eu )não estou logado") do
  Capybara.reset_session!
end

Dado("que eu estou na página de login") do
  visit login_path
end

Quando("eu faço login com a matrícula {string} e a senha {string}") do |matricula, senha|
  fazer_login(matricula, senha)
end

Quando("eu tento acessar a página inicial do estudante") do
  visit root_path
end

Quando("eu saio da minha conta") do
  click_button "Sair"
end

Então("eu devo estar na página inicial do estudante") do
  page.assert_current_path(root_path)
end

Então("eu não devo estar logado") do
  visit root_path
  page.assert_current_path(login_path)
end
