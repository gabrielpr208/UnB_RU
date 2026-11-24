# Cardápio de uma refeição em uma data. Vale para todos os restaurantes.
#
# Os itens têm uma variante (padrão, ovolactovegetariana ou vegetariana estrita). Uma variante sem item
# significa que a opção não foi cadastrada para a refeição e aparece como indisponível.
class Cardapio < ApplicationRecord
  has_many :itens, class_name: "ItemCardapio", dependent: :destroy

  enum :refeicao, { cafe_da_manha: "cafe_da_manha", almoco: "almoco", jantar: "jantar" }, validate: true

  validates :data, presence: true
  validates :refeicao, uniqueness: { scope: :data }

  # Busca o prato principal de uma variante do cardápio.
  #
  # Argumentos::
  #   - +variante+: variante do prato (ex.: +:padrao+, +:vegetariano_estrito+), como símbolo ou texto.
  # Retorno::
  #   - +String+ com a descrição do prato principal da variante;
  #   - +nil+ se a opção não foi cadastrada.
  # Efeitos colaterais:: nenhum.
  def prato(variante)
    itens.find { |item| item.prato_principal? && item.variante == variante.to_s }&.descricao
  end
end
