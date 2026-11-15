Então("(eu )devo ver a mensagem {string}") do |mensagem|
  page.assert_text(mensagem)
end

Então("(eu )devo ser redirecionado para a página de login") do
  page.assert_current_path(login_path)
end

Dado("que agora são {hora} de {data}") do |(hora, minuto), data|
  travel_to Time.zone.local(data.year, data.month, data.day, hora, minuto)
end
