# Catraca física de um restaurante, identificada por um número de 2 dígitos único dentro do restaurante.
#
# Fica "em uso" enquanto algum funcionário a tem como ponto de acesso em aberto na Aplicação de Controle,
# e nesse período não pode ser removida.
class Catraca < ApplicationRecord
  # Formato do identificador: exatamente 2 dígitos (ex.: <tt>"01"</tt>).
  IDENTIFICADOR = /\A\d{2}\z/

  # optional: true para a mensagem do formulário ser a nossa, e não o "must exist" padrão do belongs_to.
  belongs_to :restaurante, optional: true
  has_many :pontos_acesso, dependent: :destroy
  has_many :acessos

  ##
  # :method: ponto_acesso_atual
  # Ponto de acesso em aberto nesta catraca.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - o PontoAcesso em aberto;
  #   - +nil+ se nenhum funcionário está operando na catraca.
  # Efeitos colaterais:: nenhum.
  has_one :ponto_acesso_atual, -> { em_aberto }, class_name: "PontoAcesso"

  normalizes :identificador, with: ->(identificador) { identificador.strip }

  validates :restaurante, presence: { message: "Selecione um restaurante" }
  validates :identificador, presence: { message: "O identificador é obrigatório" }
  validates :identificador, format: { with: IDENTIFICADOR, message: "O identificador deve ter 2 dígitos numéricos" },
                            allow_blank: true
  validates :identificador, uniqueness: { scope: :restaurante_id,
                                          message: "Já existe uma catraca com este identificador neste restaurante" },
                            allow_blank: true

  ##
  # :singleton-method: em_ordem
  # Ordena as catracas pelo nome do restaurante e, dentro dele, pelo identificador.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>ActiveRecord::Relation</tt> de Catraca, já com o +join+ em +restaurantes+.
  # Efeitos colaterais:: nenhum.
  scope :em_ordem, -> { joins(:restaurante).order("restaurantes.nome", :identificador) }

  # Diz se algum funcionário está operando na catraca agora.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ se há um ponto de acesso em aberto na catraca; +false+ caso contrário.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def em_uso?
    pontos_acesso.em_aberto.exists?
  end

  # Remove a catraca, a não ser que esteja em uso ou tenha acessos registrados.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - a própria catraca, quando a remoção dá certo;
  #   - +false+ quando a catraca está em uso ou tem acessos registrados.
  # Efeitos colaterais::
  #   apaga a catraca e os pontos de acesso dela do banco. Na recusa, nada é apagado e o motivo
  #   fica em <tt>errors[:base]</tt>.
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
