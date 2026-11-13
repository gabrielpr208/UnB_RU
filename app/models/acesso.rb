# Entrada do estudante no restaurante. Cada acesso é uma refeição paga com o saldo e aparece no
# extrato como débito do valor cobrado.
class Acesso < ApplicationRecord
  belongs_to :estudante

  validates :data_hora, presence: true
  validates :valor_cobrado, numericality: { greater_than: 0 }
end
