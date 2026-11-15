# Cardápio de uma refeição em uma data. Vale para todos os restaurantes.
#
# Os itens têm uma variante (padrão, ovolactovegetariana ou vegetariana estrita). Uma variante sem item
# significa que a opção não foi cadastrada para a refeição e aparece como indisponível.
class Cardapio < ApplicationRecord
  has_many :itens, class_name: "ItemCardapio", dependent: :destroy

  enum :refeicao, { cafe_da_manha: "cafe_da_manha", almoco: "almoco", jantar: "jantar" }, validate: true

  validates :data, presence: true
  validates :refeicao, uniqueness: { scope: :data }

  # Prato da variante pedida, ou nil se a opção não foi cadastrada.
  def prato(variante)
    itens.find { |item| item.prato_principal? && item.variante == variante.to_s }&.descricao
  end
end
