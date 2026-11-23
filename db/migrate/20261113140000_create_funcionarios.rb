class CreateFuncionarios < ActiveRecord::Migration[8.1]
  def change
    # FUNCIONARIO especializa USUARIO, como ESTUDANTE: a chave primária é a própria referência ao usuário.
    create_table :funcionarios, primary_key: :usuario_id do |t|
      t.string :siape, null: false, limit: 7
      t.boolean :administrador, null: false, default: false

      t.timestamps
    end

    add_index :funcionarios, :siape, unique: true
    add_foreign_key :funcionarios, :usuarios, column: :usuario_id
  end
end
