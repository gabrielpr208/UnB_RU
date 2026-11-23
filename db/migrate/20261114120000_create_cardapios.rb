class CreateCardapios < ActiveRecord::Migration[8.1]
  def change
    create_table :cardapios do |t|
      t.date :data, null: false
      t.string :refeicao, null: false

      t.timestamps
    end

    add_index :cardapios, %i[ data refeicao ], unique: true
    add_check_constraint :cardapios, "refeicao IN ('cafe_da_manha', 'almoco', 'jantar')", name: "refeicao_valida"
  end
end
