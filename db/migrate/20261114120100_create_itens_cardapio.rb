class CreateItensCardapio < ActiveRecord::Migration[8.1]
  def change
    create_table :itens_cardapio do |t|
      t.references :cardapio, null: false, foreign_key: true
      t.string :categoria, null: false
      t.string :variante
      t.string :descricao, null: false

      t.timestamps
    end

    add_check_constraint :itens_cardapio,
                         "variante IS NULL OR variante IN ('padrao', 'ovolactovegetariano', 'vegetariano_estrito')",
                         name: "variante_valida"
  end
end
