# Nome próprio de estudante, como "Lucas" ou "Maria". Começa com maiúscula para não se confundir com
# o passo genérico "que eu estou logado como estudante".
ParameterType(
  name: "nome",
  regexp: /\p{Lu}\p{Ll}+/,
  transformer: ->(nome) { nome }
)

module ExtratoSteps
  def estudantes
    @estudantes ||= {}
  end

  def criar_estudante_chamado(nome)
    estudantes[nome] = criar_estudante_com_login(nome:, matricula: format("2310%05d", estudantes.size + 1))
  end

  # Linha da tabela da feature: | recarga | 20,00 | 12/10/2026 10:00 | ou | refeição | -4,50 | ... |
  def registrar_movimentacao(estudante, tipo:, valor:, data_hora:)
    valor = ValorMonetario.new.cast(valor.delete_prefix("-"))
    quando = Time.zone.strptime(data_hora, "%d/%m/%Y %H:%M")

    case tipo
    when "recarga" then estudante.recargas.create!(metodo: :cartao, status: :confirmada, valor:, confirmada_em: quando)
    when "refeição" then estudante.acessos.create!(valor_cobrado: valor, data_hora: quando)
    else raise ArgumentError, "Tipo de movimentação desconhecido: #{tipo}"
    end
  end

  # Lê a tabela do extrato no mesmo formato da feature: "+R$ 20,00" vira "20,00" e "-R$ 4,50" vira "-4,50".
  def movimentacoes_na_tela
    all(".extrato tbody tr").map do |linha|
      [
        linha.find(".movimentacao__tipo").text.downcase,
        linha.find(".movimentacao__valor").text.gsub(/[R$+\s]/, ""),
        linha.find(".movimentacao__data").text
      ]
    end
  end

  def filtrar_por_tipo(tipo)
    choose tipo
    click_button "Filtrar"
  end
end
World(ExtratoSteps)

Dado("que o/a estudante {nome} tem uma conta com as seguintes movimentações:") do |nome, tabela|
  estudante = criar_estudante_chamado(nome)
  tabela.symbolic_hashes.each { |linha| registrar_movimentacao(estudante, **linha) }
end

Dado("(que )o/a estudante {nome} tem uma conta sem movimentações") do |nome|
  criar_estudante_chamado(nome)
end

Dado("que (eu )estou logado como {nome}") do |nome|
  @estudante = estudantes.fetch(nome)

  visit login_path
  fazer_login(@estudante.matricula, AutenticacaoSteps::SENHA_PADRAO)
  page.assert_current_path(root_path)
end

Dado("que (eu )estou consultando o meu extrato") do
  visit extrato_path
end

Dado("que (eu )filtrei o extrato para mostrar apenas {string}") do |tipo|
  filtrar_por_tipo(tipo)
end

Quando("(eu )consulto o meu extrato") do
  visit extrato_path
end

Quando("(eu )tento consultar o extrato") do
  visit extrato_path
end

Quando("(eu )filtro o extrato para mostrar apenas {string}") do |tipo|
  filtrar_por_tipo(tipo)
end

Quando("(eu )filtro o extrato de {string} até {string}") do |inicio, fim|
  fill_in "Data inicial", with: Date.strptime(inicio, "%d/%m/%Y")
  fill_in "Data final", with: Date.strptime(fim, "%d/%m/%Y")
  click_button "Filtrar"
end

Quando("(eu )filtro o extrato com valores entre {string} e {string}") do |minimo, maximo|
  fill_in "Valor mínimo", with: minimo
  fill_in "Valor máximo", with: maximo
  click_button "Filtrar"
end

Quando("(eu )limpo os filtros") do
  click_link "Limpar filtros"
end

Então("(eu )devo ver as seguintes movimentações, nesta ordem:") do |tabela|
  tabela.diff!([ %w[ tipo valor data_hora ], *movimentacoes_na_tela ])
end

Então("(eu )devo ver {int} movimentações") do |quantidade|
  page.assert_selector(".extrato tbody tr", count: quantidade)
end

Então("nenhuma movimentação deve ser listada") do
  page.assert_no_selector(".extrato tbody tr")
end
