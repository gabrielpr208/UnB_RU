# Só a tabela e o vínculo com o restaurante, para impedir a remoção de restaurantes com catracas
# (features/gerencia_restaurantes.feature). O cadastro de catracas vem em features/gerencia_catracas.feature.
class CreateCatracas < ActiveRecord::Migration[8.1]
  def change
    create_table :catracas do |t|
      t.references :restaurante, null: false, index: false, foreign_key: true
      t.string :identificador, null: false, limit: 2

      t.timestamps
    end

    add_index :catracas, %i[ restaurante_id identificador ], unique: true
  end
end
