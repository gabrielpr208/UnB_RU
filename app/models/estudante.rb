class Estudante < ApplicationRecord
  self.primary_key = :usuario_id

  belongs_to :usuario

  delegate :nome, :email, to: :usuario

  normalizes :matricula, with: ->(matricula) { matricula.strip }

  validates :matricula, presence: { message: "A matrícula é obrigatória" }
  validates :matricula, format: { with: /\A\d*\z/, message: "A matrícula deve conter apenas números" },
                        allow_blank: true
  validates :matricula, length: { is: 9, message: "A matrícula deve conter 9 dígitos" },
                        allow_blank: true,
                        if: -> { matricula.to_s.match?(/\A\d+\z/) }
  validates :matricula, uniqueness: { message: "Esta matrícula já está cadastrada" }, allow_blank: true

  validates :saldo, numericality: { greater_than_or_equal_to: 0 }
end
