Então("(eu )devo ver a mensagem {string}") do |mensagem|
  page.assert_text(mensagem)
end

Então("(eu )devo ser redirecionado para a página de login") do
  page.assert_current_path(login_path)
end
