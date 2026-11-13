class CreateRestaurantes < ActiveRecord::Migration[8.1]
  def change
    create_table :restaurantes do |t|
      t.string :nome, null: false, limit: 50
      t.string :campus, null: false

      t.timestamps
    end

    add_index :restaurantes, :nome, unique: true
    add_check_constraint :restaurantes, "campus IN ('Darcy Ribeiro', 'Gama', 'Ceilândia', 'Planaltina')",
                         name: "campus_valido"
  end
end
