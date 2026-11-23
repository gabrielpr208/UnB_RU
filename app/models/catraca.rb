# Catraca física de um restaurante, identificada por um número de 2 dígitos único dentro do restaurante.
#
# Fica "em uso" enquanto algum funcionário a tem como ponto de acesso em aberto na Aplicação de Controle,
# e nesse período não pode ser removida.
class Catraca < ApplicationRecord
  IDENTIFICADOR = /\A\d{2}\z/

  # optional: true para a mensagem do formulário ser a nossa, e não o "must exist" padrão do belongs_to.
  belongs_to :restaurante, optional: true
  has_many :pontos_acesso, dependent: :destroy
  has_many :acessos
  # Ponto de acesso em aberto nesta catraca, ou nil se nenhum funcionário está operando nela.
  has_one :ponto_acesso_atual, -> { em_aberto }, class_name: "PontoAcesso"

  normalizes :identificador, with: ->(identificador) { identificador.strip }

  validates :restaurante, presence: { message: "Selecione um restaurante" }
  validates :identificador, presence: { message: "O identificador é obrigatório" }
  validates :identificador, format: { with: IDENTIFICADOR, message: "O identificador deve ter 2 dígitos numéricos" },
                            allow_blank: true
  validates :identificador, uniqueness: { scope: :restaurante_id,
                                          message: "Já existe uma catraca com este identificador neste restaurante" },
                            allow_blank: true

  scope :em_ordem, -> { joins(:restaurante).order("restaurantes.nome", :identificador) }

  def em_uso?
    pontos_acesso.em_aberto.exists?
  end

  # Remove a catraca, a não ser que esteja em uso. Devolve false e deixa o motivo em `errors`.
  def remover
    if em_uso?
      errors.add(:base, "Não é possível remover uma catraca em uso")
      false
    elsif acessos.exists?
      errors.add(:base, "Não é possível remover uma catraca com acessos registrados")
      false
    else
      destroy
    end
  end
end
