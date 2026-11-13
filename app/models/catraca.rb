# Catraca física de um restaurante, identificada por um número de 2 dígitos único dentro do restaurante.
class Catraca < ApplicationRecord
  belongs_to :restaurante

  validates :identificador, presence: { message: "O identificador é obrigatório" }
  validates :identificador, format: { with: /\A\d{2}\z/, message: "O identificador deve ter 2 dígitos numéricos" },
                            allow_blank: true
  validates :identificador, uniqueness: { scope: :restaurante_id,
                                          message: "Já existe uma catraca com este identificador neste restaurante" },
                            allow_blank: true
end
