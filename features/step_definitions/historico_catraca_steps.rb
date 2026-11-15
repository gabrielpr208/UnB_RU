module HistoricoCatracaSteps
  def catraca_chamada(identificador, nome_ru)
    restaurante_chamado(nome_ru).catracas.find_or_create_by!(identificador:)
  end

  def acessos_no_historico
    all(".historico tbody tr").map do |linha|
      [
        linha.find(".acesso__identificacao").text,
        "#{linha.find('.acesso__data').text} #{linha.find('.acesso__hora').text}"
      ]
    end
  end
end
World(HistoricoCatracaSteps)

Dado("que a catraca {string} do {string} tem os seguintes acessos:") do |identificador, nome_ru, tabela|
  catraca = catraca_chamada(identificador, nome_ru)

  tabela.hashes.each do |linha|
    catraca.acessos.create!(
      estudante: estudante_com_matricula(linha["identificação"]),
      data_hora: Time.zone.strptime(linha["data_hora"], "%d/%m/%Y %H:%M"),
      valor_cobrado: 5.20
    )
  end
end

Dado("que a catraca {string} do {string} está configurada como ponto de acesso") do |identificador, nome_ru|
  PontoAcesso.abrir!(funcionario: @funcionario, catraca: catraca_chamada(identificador, nome_ru))
end

Dado("que nenhuma catraca está configurada como ponto de acesso") do
  expect(@funcionario.ponto_acesso_atual).to be_nil
end

Quando("(eu )consulto o histórico") do
  visit controle_historico_path
end

Quando("(eu )tento consultar o histórico") do
  visit controle_historico_path
end

Então("(eu )devo ver os seguintes acessos, nesta ordem:") do |tabela|
  tabela.diff!([ %w[identificação data_hora], *acessos_no_historico ])
end

Então("(eu )devo ser redirecionado para a página de configuração de ponto de acesso") do
  page.assert_current_path(controle_ponto_acesso_path)
end
