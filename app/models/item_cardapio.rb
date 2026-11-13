class ItemCardapio < ApplicationRecord
  PRATO_PRINCIPAL = "prato_principal".freeze

  self.table_name = "itens_cardapio"

  belongs_to :cardapio

  enum :variante, {
    padrao: "padrao",
    ovolactovegetariano: "ovolactovegetariano",
    vegetariano_estrito: "vegetariano_estrito"
  }, validate: { allow_nil: true }

  validates :categoria, :descricao, presence: true

  def prato_principal?
    categoria == PRATO_PRINCIPAL
  end
end
