ParameterType(
  name: "reais",
  regexp: /R\$ \d{1,3}(?:\.\d{3})*,\d{2}/,
  transformer: ->(texto) { ValorMonetario.new.cast(texto) }
)

module RecargaSaldoSteps
  ABAS = { "PIX" => "PIX", "cartão de crédito" => "Cartão de crédito" }.freeze
  BOTOES = { "PIX" => "Gerar código PIX", "cartão de crédito" => "Efetuar pagamento" }.freeze

  def solicitar_recarga(valor, forma)
    click_link ABAS.fetch(forma)
    fill_in "Valor da recarga", with: valor
    click_button BOTOES.fetch(forma)
  end

  def gerar_codigo_pix(valor)
    solicitar_recarga(ValorMonetario.formatar(valor).delete_prefix("R$ "), "PIX")
    page.assert_selector(:button, "Conferir pagamento")
  end
end
World(RecargaSaldoSteps, ActiveSupport::Testing::TimeHelpers)

After { travel_back }

Dado("que meu saldo atual é de {reais}") do |saldo|
  @estudante.update!(saldo:)
end

Dado("que eu estou na página de adicionar créditos") do
  visit nova_recarga_path
end

Dado("que eu gerei um código PIX de {reais} há menos de 1 minuto") do |valor|
  gerar_codigo_pix(valor)
  travel Recarga::VALIDADE_DO_PIX - 10.seconds
end

Dado("que eu gerei um código PIX de {reais} há mais de 1 minuto") do |valor|
  gerar_codigo_pix(valor)
  travel Recarga::VALIDADE_DO_PIX + 1.second
end

Quando("eu solicito uma recarga de {string} via {string}") do |valor, forma|
  solicitar_recarga(valor, forma)
end

Quando("eu confirmo o pagamento") do
  click_button "Conferir pagamento"
end

Quando("eu pago uma recarga de {string} com o cartão {string}, validade {string} e CVV {string}") do |valor, numero, validade, cvv|
  click_link "Cartão de crédito"
  fill_in "Valor da recarga", with: valor
  fill_in "Número do cartão", with: numero
  fill_in "Validade", with: validade
  fill_in "CVV", with: cvv
  click_button "Efetuar pagamento"
end

Então("eu devo ver o código PIX para pagamento") do
  page.assert_selector("svg.qrcode")
  page.assert_selector(:field, "Pix copia e cola", with: @estudante.recargas.pix.last.codigo_pix)
end

Então("eu devo ver o botão {string}") do |texto|
  page.assert_selector(:button, texto)
end

Então("meu saldo deve ser de {reais}") do |saldo|
  assert_equal saldo, @estudante.reload.saldo
end

Então("meu saldo deve continuar {reais}") do |saldo|
  assert_equal saldo, @estudante.reload.saldo
end
