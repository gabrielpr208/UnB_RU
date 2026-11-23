module ConfiguracaoPontoAcessoSteps
  # Chaves da tabela "eu configuro o ponto de acesso com os seguintes dados:" para os rótulos do formulário.
  CAMPOS_DO_PONTO_ACESSO = { "restaurante" => "Restaurante", "número da catraca" => "Número da catraca" }.freeze

  # Parte da página inicial da Aplicação de Controle, onde o funcionário cai logo após o login.
  def configurar_ponto_acesso(dados)
    visit controle_path
    click_link "Configurar ponto de acesso"
    dados.each { |campo, valor| fill_in CAMPOS_DO_PONTO_ACESSO.fetch(campo), with: valor }
    click_button "Confirmar ponto de acesso"
  end
end
World(ConfiguracaoPontoAcessoSteps)

Dado("que eu acabei de fazer login bem-sucedido como funcionário") do
  @funcionario = criar_funcionario_com_login

  fazer_login_de_funcionario("SIAPE" => @funcionario.siape, "senha" => AutenticacaoSteps::SENHA_PADRAO)
  page.assert_current_path(controle_path)
end

Dado("(que )o restaurante {string} existe") do |nome|
  @restaurante = Restaurante.create!(nome:, campus: "Darcy Ribeiro")
end

Dado("(que )a catraca {string} é a única desse restaurante") do |identificador|
  @restaurante.catracas.create!(identificador:)
  expect(@restaurante.catracas.pluck(:identificador)).to eq([ identificador ])
end

Quando("eu configuro o ponto de acesso com os seguintes dados:") do |tabela|
  configurar_ponto_acesso(tabela.rows_hash)
end

Quando("eu configuro o ponto de acesso com {string} e {string}") do |restaurante, catraca|
  configurar_ponto_acesso("restaurante" => restaurante, "número da catraca" => catraca)
end

Então("(eu )devo permanecer na seleção de ponto de acesso") do
  page.assert_current_path(controle_ponto_acesso_path)
  page.assert_selector(:button, "Confirmar ponto de acesso")
  expect(@funcionario.reload.ponto_acesso_atual).to be_nil
end
