# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_13_140000) do
  create_table "acessos", force: :cascade do |t|
    t.integer "estudante_id", null: false
    t.datetime "data_hora", null: false
    t.decimal "valor_cobrado", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estudante_id", "data_hora"], name: "index_acessos_on_estudante_id_and_data_hora"
    t.check_constraint "valor_cobrado > 0", name: "valor_cobrado_positivo"
  end

  create_table "estudantes", primary_key: "usuario_id", force: :cascade do |t|
    t.string "matricula", limit: 9, null: false
    t.decimal "saldo", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["matricula"], name: "index_estudantes_on_matricula", unique: true
    t.check_constraint "saldo >= 0", name: "saldo_nao_negativo"
  end

  create_table "funcionarios", primary_key: "usuario_id", force: :cascade do |t|
    t.string "siape", limit: 7, null: false
    t.boolean "administrador", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["siape"], name: "index_funcionarios_on_siape", unique: true
  end

  create_table "recargas", force: :cascade do |t|
    t.integer "estudante_id", null: false
    t.decimal "valor", precision: 10, scale: 2, null: false
    t.string "metodo", null: false
    t.string "status", default: "pendente", null: false
    t.string "codigo_pix"
    t.datetime "expira_em"
    t.datetime "confirmada_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["codigo_pix"], name: "index_recargas_on_codigo_pix", unique: true
    t.index ["estudante_id"], name: "index_recargas_on_estudante_id"
    t.check_constraint "metodo = 'cartao' OR (codigo_pix IS NOT NULL AND expira_em IS NOT NULL)", name: "pix_com_codigo_e_prazo"
    t.check_constraint "metodo IN ('pix', 'cartao')", name: "metodo_valido"
    t.check_constraint "status IN ('pendente', 'confirmada', 'expirada')", name: "status_valido"
    t.check_constraint "valor >= 1 AND valor <= 1000", name: "valor_dentro_do_limite"
  end

  create_table "sessoes", force: :cascade do |t|
    t.integer "usuario_id", null: false
    t.string "endereco_ip"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["usuario_id"], name: "index_sessoes_on_usuario_id"
  end

  create_table "usuarios", force: :cascade do |t|
    t.string "nome", null: false
    t.string "email", null: false
    t.string "senha_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_usuarios_on_email", unique: true
  end

  add_foreign_key "acessos", "estudantes", primary_key: "usuario_id"
  add_foreign_key "estudantes", "usuarios"
  add_foreign_key "funcionarios", "usuarios"
  add_foreign_key "recargas", "estudantes", primary_key: "usuario_id"
  add_foreign_key "sessoes", "usuarios"
end
