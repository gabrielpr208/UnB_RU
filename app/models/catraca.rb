# Catraca física de um restaurante, identificada por um número de 2 dígitos único dentro do restaurante.
class Catraca < ApplicationRecord
  IDENTIFICADOR = /\A\d{2}\z/

  belongs_to :restaurante
  has_many :pontos_acesso, dependent: :destroy

  validates :identificador, presence: { message: "O identificador é obrigatório" }
  validates :identificador, format: { with: IDENTIFICADOR, message: "O identificador deve ter 2 dígitos numéricos" },
                            allow_blank: true
  validates :identificador, uniqueness: { scope: :restaurante_id,
                                          message: "Já existe uma catraca com este identificador neste restaurante" },
                            allow_blank: true
end
