# Ponto de acesso: a catraca de um restaurante em que um funcionário está operando na Aplicação de Controle.
# O funcionário o configura logo após o login, e ele fica em aberto (encerrado_em nulo) até o funcionário trocar
# de catraca ou sair. As regras da catraca e os registros de acesso usam o ponto em aberto.
#
# Cada funcionário opera uma catraca por vez, e cada catraca é operada por um funcionário por vez: ao abrir um
# ponto, são encerrados o anterior do funcionário e o de quem estava na catraca (ex.: troca de turno).
class PontoAcesso < ApplicationRecord
  belongs_to :funcionario
  belongs_to :catraca

  delegate :restaurante, to: :catraca

  validates :iniciado_em, presence: true

  scope :em_aberto, -> { where(encerrado_em: nil) }

  def self.abrir!(funcionario:, catraca:, agora: Time.current)
    transaction do
      where(funcionario:).or(where(catraca:)).encerrar(agora)
      create!(funcionario:, catraca:, iniciado_em: agora)
    end
  end

  # Encerra os pontos em aberto da relação (ex.: funcionario.pontos_acesso.encerrar).
  def self.encerrar(agora = Time.current)
    em_aberto.update_all(encerrado_em: agora, updated_at: agora)
  end
end
