module ValidacaoEntradaSteps
  def estudante_chamado(nome)
    Estudante.joins(:usuario).find_by!(usuarios: { nome: })
  end
end
World(ValidacaoEntradaSteps)

Dado('que o estudante {nome}, com a matrícula {string}, existe no sistema') do |nome, matricula|
  @estudante = criar_estudante_com_login(nome:, matricula:)
end

Dado('que o preço de uma refeição é {reais}') do |valor|
  @preco_refeicao = valor
  PrecoRefeicao::REFEICOES.each { |refeicao| PrecoRefeicao.create!(refeicao:, valor:) }
end

Dado('que a catraca {string} do {string} está configurada') do |id_catraca, nome_ru|
  restaurante = restaurante_chamado(nome_ru)
  @catraca = restaurante.catracas.create!(identificador: id_catraca)

  @funcionario ||= criar_funcionario_com_login
  @senha_do_funcionario ||= AutenticacaoSteps::SENHA_PADRAO
  fazer_login_de_funcionario("SIAPE" => @funcionario.siape, "senha" => @senha_do_funcionario)
  PontoAcesso.abrir!(funcionario: @funcionario, catraca: @catraca)
end

Dado('que {nome} tem {reais} de saldo') do |nome, saldo|
  estudante_chamado(nome).update!(saldo:)
end

Quando('eu apresento a identificação {string} na catraca {string} do {string}') do |identificacao, id_catraca, nome_ru|
  ponto = @funcionario.ponto_acesso_atual
  expect(ponto.catraca.identificador).to eq(id_catraca)
  expect(ponto.restaurante.nome).to eq(nome_ru)

  visit controle_entrada_path
  fill_in "Matrícula", with: identificacao
  click_button "Validar entrada"
end

Então('a catraca deve ser liberada') do
  expect(page).to have_css("[data-catraca='liberada']")
end

Então('o saldo de {nome} deve ser/permanecer {reais}') do |nome, saldo|
  expect(estudante_chamado(nome).saldo).to eq(saldo)
end

Então('o acesso deve ser registrado no histórico da catraca') do
  acesso = @catraca.acessos.sole
  expect(acesso.estudante).to eq(@estudante)
  expect(acesso.valor_cobrado).to eq(@preco_refeicao)
end

Então('a catraca deve permanecer bloqueada') do
  expect(page).to have_css("[data-catraca='bloqueada']")
end

Então('nenhum acesso deve ser registrado no histórico da catraca') do
  expect(@catraca.acessos).to be_empty
end
