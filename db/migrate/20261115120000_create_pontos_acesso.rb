# Catraca em que o funcionário está operando na Aplicação de Controle (features/configuracao_ponto_acesso.feature).
# Fica em aberto (encerrado_em nulo) enquanto a catraca está em uso; os encerrados guardam quem operou cada
# catraca e quando.
class CreatePontosAcesso < ActiveRecord::Migration[8.1]
  def change
    create_table :pontos_acesso do |t|
      t.references :funcionario, null: false, foreign_key: { primary_key: :usuario_id }
      t.references :catraca, null: false, foreign_key: true
      t.datetime :iniciado_em, null: false
      t.datetime :encerrado_em

      t.timestamps
    end

    # Cada funcionário opera uma catraca por vez, e cada catraca é operada por um funcionário por vez.
    add_index :pontos_acesso, :funcionario_id, unique: true, where: "encerrado_em IS NULL",
                                               name: "index_pontos_acesso_em_aberto_por_funcionario"
    add_index :pontos_acesso, :catraca_id, unique: true, where: "encerrado_em IS NULL",
                                           name: "index_pontos_acesso_em_aberto_por_catraca"
    add_check_constraint :pontos_acesso, "encerrado_em IS NULL OR encerrado_em >= iniciado_em",
                         name: "encerrado_depois_de_iniciado"
  end
end
