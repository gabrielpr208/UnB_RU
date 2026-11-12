class CreateRecargas < ActiveRecord::Migration[8.1]
  def change
    create_table :recargas do |t|
      t.references :estudante, null: false, foreign_key: { primary_key: :usuario_id }
      t.decimal :valor, precision: 10, scale: 2, null: false
      t.string :metodo, null: false
      t.string :status, null: false, default: "pendente"
      t.string :codigo_pix
      t.datetime :expira_em
      t.datetime :confirmada_em

      t.timestamps
    end

    add_index :recargas, :codigo_pix, unique: true
    add_check_constraint :recargas, "valor >= 1 AND valor <= 1000", name: "valor_dentro_do_limite"
    add_check_constraint :recargas, "metodo IN ('pix', 'cartao')", name: "metodo_valido"
    add_check_constraint :recargas, "status IN ('pendente', 'confirmada', 'expirada')", name: "status_valido"
    add_check_constraint :recargas, "metodo = 'cartao' OR (codigo_pix IS NOT NULL AND expira_em IS NOT NULL)",
                         name: "pix_com_codigo_e_prazo"
  end
end
