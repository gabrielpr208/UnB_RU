# Item de um Cardapio (ex.: prato principal ou bebida). Os pratos principais têm uma variante.
class ItemCardapio < ApplicationRecord
  # Categoria dos itens que são o prato principal da refeição.
  PRATO_PRINCIPAL = "prato_principal".freeze

  self.table_name = "itens_cardapio"

  belongs_to :cardapio

  enum :variante, {
    padrao: "padrao",
    ovolactovegetariano: "ovolactovegetariano",
    vegetariano_estrito: "vegetariano_estrito"
  }, validate: { allow_nil: true }

  validates :categoria, :descricao, presence: true

  # Diz se o item é o prato principal da refeição.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ se a categoria é PRATO_PRINCIPAL; +false+ caso contrário.
  # Efeitos colaterais:: nenhum.
  def prato_principal?
    categoria == PRATO_PRINCIPAL
  end
end
