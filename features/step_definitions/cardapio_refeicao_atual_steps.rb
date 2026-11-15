ParameterType(
  name: "data",
  regexp: %r{\d{2}/\d{2}/\d{4}},
  transformer: ->(data) { Date.strptime(data, "%d/%m/%Y") }
)

ParameterType(
  name: "hora",
  regexp: /\d{2}:\d{2}/,
  transformer: ->(hora) { hora.split(":").map(&:to_i) }
)

module CardapioSteps
  REFEICOES = {
    "Café da manhã" => "cafe_da_manha",
    "Almoço" => "almoco",
    "Jantar" => "jantar"
  }.freeze

  VARIANTES = %w[ padrao ovolactovegetariano vegetariano_estrito ].freeze

  def cardapios
    @cardapios ||= {}
  end

  # Linha da tabela da feature: | Almoço | Frango grelhado | Omelete de legumes | (vazio) |
  # Célula vazia significa que a opção não foi cadastrada.
  def cadastrar_cardapio(data, linha)
    cardapio = Cardapio.create!(data:, refeicao: REFEICOES.fetch(linha[:refeicao]))

    VARIANTES.each do |variante|
      descricao = linha[variante.to_sym]
      cardapio.itens.create!(categoria: ItemCardapio::PRATO_PRINCIPAL, variante:, descricao:) if descricao.present?
    end

    cardapios[linha[:refeicao]] = cardapio
  end

  # Texto que a tela mostra para a opção (ex.: "Padrão" -> "Frango grelhado").
  def prato_da_opcao(opcao)
    find("dt", text: opcao, exact_text: true).find(:xpath, "following-sibling::dd[1]").text
  end
end
World(CardapioSteps)
World(ActiveSupport::Testing::TimeHelpers)

After { travel_back }

Dado("que o cardápio de {data} é:") do |data, tabela|
  tabela.symbolic_hashes.each { |linha| cadastrar_cardapio(data, linha) }
end

Dado("que agora são {hora} de {data}") do |(hora, minuto), data|
  travel_to Time.zone.local(data.year, data.month, data.day, hora, minuto)
end

Quando("eu acesso o cardápio") do
  visit cardapio_path
end

Então("eu devo ver o cardápio do {string}") do |refeicao|
  page.assert_selector "h2", text: "Cardápio do #{refeicao}"
  page.assert_text cardapios.fetch(refeicao).prato(:padrao)
end

Então("eu devo ver as seguintes opções:") do |tabela|
  tabela.symbolic_hashes.each do |linha|
    expect(prato_da_opcao(linha[:opcao])).to eq(linha[:prato])
  end
end

Então("eu devo ver que a próxima refeição é {string}") do |proxima|
  page.assert_selector ".alerta__texto strong", text: proxima, exact_text: true
end

Então("eu devo ver a opção {string} com o prato {string}") do |opcao, prato|
  expect(prato_da_opcao(opcao)).to eq(prato)
end

Então("eu devo ver a opção {string} como {string}") do |opcao, texto|
  expect(prato_da_opcao(opcao)).to eq(texto)
end
