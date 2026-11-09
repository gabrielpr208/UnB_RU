module CadastroEstudanteSteps
  DADOS_VALIDOS = {
    "nome" => "Maria Souza",
    "matricula" => "231012345",
    "email" => "maria@aluno.unb.br",
    "senha" => "senha123",
    "confirmacao_senha" => "senha123"
  }.freeze

  ROTULOS = {
    "nome" => "Nome completo",
    "matricula" => "Matrícula",
    "email" => "E-mail",
    "senha" => "Senha",
    "confirmacao_senha" => "Confirmação de senha"
  }.freeze

  def cadastrar_estudante(dados)
    @total_usuarios_antes = Usuario.count
    @total_estudantes_antes = Estudante.count

    dados.each { |campo, valor| fill_in ROTULOS.fetch(campo), with: valor }
    click_button "Criar conta"
  end
end
World(CadastroEstudanteSteps)

Dado("que eu estou na página de cadastro") do
  visit cadastro_path
end

Dado("que já existe um estudante cadastrado com a matrícula {string}") do |matricula|
  usuario = Usuario.create!(nome: "Estudante Existente", email: "existente@aluno.unb.br", senha: "senha123")
  Estudante.create!(usuario:, matricula:)
end

Quando("eu me cadastro com os seguintes dados:") do |tabela|
  cadastrar_estudante(tabela.rows_hash)
end

Quando("eu me cadastro com a matrícula {string} e os demais dados válidos") do |matricula|
  cadastrar_estudante(CadastroEstudanteSteps::DADOS_VALIDOS.merge("matricula" => matricula))
end

Quando("eu me cadastro com a senha {string} e a confirmação {string}") do |senha, confirmacao|
  cadastrar_estudante(CadastroEstudanteSteps::DADOS_VALIDOS.merge("senha" => senha, "confirmacao_senha" => confirmacao))
end

Então("minha conta não deve ser criada") do
  assert_equal @total_usuarios_antes, Usuario.count
  assert_equal @total_estudantes_antes, Estudante.count
  page.assert_current_path(cadastro_path)
end
