# Restaurante universitário de um dos campi. Os funcionários o escolhem na Aplicação de Controle ao
# configurar o ponto de acesso, e as catracas ficam vinculadas a ele.
class Restaurante < ApplicationRecord
  # Campi da UnB que podem ter restaurante.
  CAMPI = [ "Darcy Ribeiro", "Gama", "Ceilândia", "Planaltina" ].freeze
  # Quantidade de caracteres aceita no nome.
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

  ##
  # :singleton-method: em_ordem
  # Ordena os restaurantes pelo nome.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>ActiveRecord::Relation</tt> de Restaurante.
  # Efeitos colaterais:: nenhum.
  scope :em_ordem, -> { order(:nome) }

  # Remove o restaurante, a não ser que ele tenha catracas.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - o próprio restaurante, quando a remoção dá certo;
  #   - +false+ quando o restaurante tem catracas cadastradas.
  # Efeitos colaterais::
  #   apaga o restaurante do banco. Na recusa, nada é apagado e o motivo fica em <tt>errors[:base]</tt>.
  def remover
    if catracas.exists?
      errors.add(:base, "Não é possível remover um restaurante com catracas cadastradas")
      false
    else
      destroy
    end
  end
end
