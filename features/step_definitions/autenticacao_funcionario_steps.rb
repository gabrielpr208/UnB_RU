module AutenticacaoFuncionarioSteps
  # Rótulos dos campos do formulário para as chaves da tabela "eu faço login com os seguintes dados:".
  CAMPOS_DO_LOGIN = { "SIAPE" => "SIAPE", "senha" => "Senha" }.freeze

  def criar_funcionario_com_login(siape:, senha:, nome: "José Pereira", administrador: false)
    usuario = Usuario.create!(nome:, email: "#{siape}@unb.br", senha:)
    Funcionario.create!(usuario:, siape:, administrador:)
  end

  def fazer_login_de_funcionario(dados)
    visit login_controle_path
    dados.each { |campo, valor| fill_in CAMPOS_DO_LOGIN.fetch(campo), with: valor }
    click_button "Entrar"
  end
end
World(AutenticacaoFuncionarioSteps)

Dado("que existe o funcionário com SIAPE {string} e senha {string}") do |siape, senha|
  @funcionario = criar_funcionario_com_login(siape:, senha:)
  @senha_do_funcionario = senha
end

Dado("que (eu )estou logado como funcionário") do
  @funcionario ||= criar_funcionario_com_login(siape: "1234567", senha: AutenticacaoSteps::SENHA_PADRAO)
  @senha_do_funcionario ||= AutenticacaoSteps::SENHA_PADRAO

  fazer_login_de_funcionario("SIAPE" => @funcionario.siape, "senha" => @senha_do_funcionario)
  page.assert_current_path(controle_path)
end

Dado("que (eu )estou logado como administrador") do
  @funcionario ||= criar_funcionario_com_login(siape: "7654321", senha: AutenticacaoSteps::SENHA_PADRAO,
                                               nome: "Ana Lima", administrador: true)
  @senha_do_funcionario ||= AutenticacaoSteps::SENHA_PADRAO

  fazer_login_de_funcionario("SIAPE" => @funcionario.siape, "senha" => @senha_do_funcionario)
  page.assert_current_path(controle_path)
end

Quando("eu faço login com os seguintes dados:") do |tabela|
  fazer_login_de_funcionario(tabela.rows_hash)
end

Quando("eu tento fazer login com {string} e {string}") do |siape, senha|
  fazer_login_de_funcionario("SIAPE" => siape, "senha" => senha)
end

Quando("eu tento acessar a aplicação de controle") do
  visit controle_path
end

Então("(eu )devo ser redirecionado para a página de/da aplicação de controle") do
  page.assert_current_path(controle_path)
end

Então("(eu )devo ser redirecionado para a página de login de funcionário") do
  page.assert_current_path(login_controle_path)
end

Então("(eu )não devo ter acesso à aplicação de controle") do
  visit controle_path
  page.assert_current_path(login_controle_path)
end
