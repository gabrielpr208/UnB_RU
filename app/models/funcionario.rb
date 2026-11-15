# Funcionário do RU, que entra na Aplicação de Controle com o SIAPE (equivalente à matrícula) e a senha.
class Funcionario < ApplicationRecord
  include EspecializacaoDeUsuario

  TAMANHO_DO_SIAPE = 7

  normalizes :siape, with: ->(siape) { siape.strip }

  validates :siape, presence: { message: "O SIAPE é obrigatório" }
  validates :siape, format: { with: /\A\d*\z/, message: "O SIAPE deve conter apenas números" },
                    allow_blank: true
  validates :siape, length: { is: TAMANHO_DO_SIAPE, message: "O SIAPE deve conter #{TAMANHO_DO_SIAPE} dígitos" },
                    allow_blank: true,
                    if: -> { siape.to_s.match?(/\A\d+\z/) }
  validates :siape, uniqueness: { message: "Este SIAPE já está cadastrado" }, allow_blank: true

  def self.autenticar(siape:, senha:)
    autenticar_por(siape:, senha:)
  end
end
