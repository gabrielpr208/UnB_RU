# Entrada do estudante no restaurante. Cada acesso é uma refeição paga com o saldo e aparece no
# extrato como débito do valor cobrado.
class Acesso < ApplicationRecord
  belongs_to :estudante
  belongs_to :catraca

  validates :data_hora, presence: true
  validates :valor_cobrado, numericality: { greater_than: 0 }

  ##
  # :singleton-method: mais_recentes
  # Ordena os acessos do mais recente para o mais antigo.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>ActiveRecord::Relation</tt> de Acesso, ordenada por +data_hora+ decrescente.
  # Efeitos colaterais:: nenhum.
  scope :mais_recentes, -> { order(data_hora: :desc) }
end
