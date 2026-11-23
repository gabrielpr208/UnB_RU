class CreateEstudantes < ActiveRecord::Migration[8.1]
  def change
    # ESTUDANTE especializa USUARIO: a chave primária é a própria referência ao usuário.
    create_table :estudantes, primary_key: :usuario_id do |t|
      t.string :matricula, null: false, limit: 9
      t.decimal :saldo, precision: 10, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :estudantes, :matricula, unique: true
    add_foreign_key :estudantes, :usuarios, column: :usuario_id
    add_check_constraint :estudantes, "saldo >= 0", name: "saldo_nao_negativo"
  end
end
