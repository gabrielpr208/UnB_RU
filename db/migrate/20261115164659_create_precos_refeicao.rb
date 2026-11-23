class CreatePrecosRefeicao < ActiveRecord::Migration[8.1]
  def change
    create_table :precos_refeicao do |t|
      t.string :refeicao
      t.decimal :valor, null: false, precision: 10, scale: 2

      t.timestamps
    end
    add_index :precos_refeicao, :refeicao, unique: true
    add_check_constraint :precos_refeicao, "valor > 0", name: "preco_positivo"
  end
end
