class CreateSessoes < ActiveRecord::Migration[8.1]
  def change
    create_table :sessoes do |t|
      t.references :usuario, null: false, foreign_key: true
      t.string :endereco_ip
      t.string :user_agent

      t.timestamps
    end
  end
end
