# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Cardápios dos próximos 7 dias, a partir de cardapio.json (que traz o cardápio semanal por dia da semana).
# Só o prato principal de cada variante é cadastrado: no café da manhã, o complemento.
DIAS_DA_SEMANA = %w[ domingo segunda-feira terca-feira quarta-feira quinta-feira sexta-feira sabado ].freeze
PRATOS_POR_REFEICAO = {
  "cafe_da_manha" => %w[ complemento_padrao complemento_ovolactovegetariano complemento_vegetariano_estrito ],
  "almoco" => %w[ prato_principal_padrao prato_principal_ovolactovegetariano prato_principal_vegetariano_estrito ],
  "jantar" => %w[ prato_principal_padrao prato_principal_ovolactovegetariano prato_principal_vegetariano_estrito ]
}.freeze

semana = JSON.parse(Rails.root.join("cardapio.json").read)

(Date.current..Date.current + 6).each do |data|
  refeicoes = semana.fetch(DIAS_DA_SEMANA[data.wday])

  PRATOS_POR_REFEICAO.each do |refeicao, campos|
    cardapio = Cardapio.find_or_create_by!(data:, refeicao:)

    ItemCardapio.variantes.keys.zip(campos).each do |variante, campo|
      descricao = refeicoes.dig(refeicao, campo)
      next if descricao.blank?

      cardapio.itens.find_or_create_by!(categoria: ItemCardapio::PRATO_PRINCIPAL, variante:) do |item|
        item.descricao = descricao
      end
    end
  end
end
