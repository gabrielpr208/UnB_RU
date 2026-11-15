# Restaurante universitário de um dos campi. Os funcionários o escolhem na Aplicação de Controle ao
# configurar o ponto de acesso, e as catracas ficam vinculadas a ele.
class Restaurante < ApplicationRecord
  CAMPI = [ "Darcy Ribeiro", "Gama", "Ceilândia", "Planaltina" ].freeze
  TAMANHO_DO_NOME = 3..50

  has_many :catracas, dependent: :restrict_with_exception

  normalizes :nome, :campus, with: ->(texto) { texto.squish }

  validates :nome, presence: { message: "O nome é obrigatório" }
  validates :nome, length: { in: TAMANHO_DO_NOME,
                             message: "O nome deve ter entre #{TAMANHO_DO_NOME.min} e #{TAMANHO_DO_NOME.max} caracteres" },
                   allow_blank: true
  validates :nome, uniqueness: { case_sensitive: false, message: "Já existe um restaurante com este nome" },
                   allow_blank: true
  validates :campus, presence: { message: "O campus é obrigatório" }
  validates :campus, inclusion: { in: CAMPI, message: "Campus inválido" }, allow_blank: true

  scope :em_ordem, -> { order(:nome) }

  # Remove o restaurante, a não ser que ele tenha catracas. Devolve false e deixa o motivo em `errors`.
  def remover
    if catracas.exists?
      errors.add(:base, "Não é possível remover um restaurante com catracas cadastradas")
      false
    else
      destroy
    end
  end
end
