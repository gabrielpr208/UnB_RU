# Cada acesso é uma refeição paga com o saldo: aparece no extrato como débito.
#
# O vínculo com a catraca (catraca_id) entra junto com o cadastro de catracas (features/gerencia_catracas.feature).
class CreateAcessos < ActiveRecord::Migration[8.1]
  def change
    create_table :acessos do |t|
      t.references :estudante, null: false, index: false, foreign_key: { primary_key: :usuario_id }
      t.datetime :data_hora, null: false
      t.decimal :valor_cobrado, precision: 10, scale: 2, null: false

      t.timestamps
    end

    # O extrato busca os acessos de um estudante dentro de um período.
    add_index :acessos, %i[ estudante_id data_hora ]
    add_check_constraint :acessos, "valor_cobrado > 0", name: "valor_cobrado_positivo"
  end
end
