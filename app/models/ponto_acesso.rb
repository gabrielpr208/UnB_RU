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

  ##
  # :singleton-method: em_aberto
  # Filtra os pontos de acesso que ainda não foram encerrados.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>ActiveRecord::Relation</tt> de PontoAcesso com +encerrado_em+ nulo.
  # Efeitos colaterais:: nenhum.
  scope :em_aberto, -> { where(encerrado_em: nil) }

  # Abre um ponto de acesso para o funcionário na catraca.
  #
  # Argumentos::
  #   - +funcionario+: Funcionario que vai operar a catraca.
  #   - +catraca+: Catraca escolhida.
  #   - +agora+: horário de abertura (padrão: +Time.current+).
  # Retorno:: o PontoAcesso criado.
  # Efeitos colaterais::
  #   numa mesma transação, encerra no banco o ponto em aberto do funcionário e o da catraca e cria o novo
  #   ponto. Levanta <tt>ActiveRecord::RecordInvalid</tt> se o ponto não puder ser gravado.
  def self.abrir!(funcionario:, catraca:, agora: Time.current)
    transaction do
      where(funcionario:).or(where(catraca:)).encerrar(agora)
      create!(funcionario:, catraca:, iniciado_em: agora)
    end
  end

  # Encerra os pontos em aberto da relação (ex.: <tt>funcionario.pontos_acesso.encerrar</tt>).
  #
  # Argumentos::
  #   - +agora+: horário de encerramento (padrão: +Time.current+).
  # Retorno:: +Integer+ com a quantidade de pontos encerrados.
  # Efeitos colaterais::
  #   preenche +encerrado_em+ e +updated_at+ dos pontos em aberto no banco, sem executar validações nem callbacks.
  def self.encerrar(agora = Time.current)
    em_aberto.update_all(encerrado_em: agora, updated_at: agora)
  end
end
