# Formulário em que o funcionário, logo após o login, escolhe o ponto de acesso em que vai operar: o restaurante
# (pelo nome) e o número da catraca (2 dígitos). Os dois precisam existir, e a catraca precisa ser do restaurante.
#
# A tela resume qualquer problema como "Ponto de acesso inválido" e mostra o detalhe no campo.
class ConfiguracaoPontoAcesso
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :restaurante, :string
  attribute :numero_da_catraca, :string

  attr_accessor :funcionario
  attr_reader :ponto_acesso

  validate :validar_restaurante
  validate :validar_catraca

  def save
    return false unless valid?

    @ponto_acesso = PontoAcesso.abrir!(funcionario:, catraca: catraca_escolhida)
    true
  end

  private

  # O nome não diferencia maiúsculas de minúsculas, como na regra de nome único do restaurante.
  def restaurante_escolhido
    return @restaurante_escolhido if defined?(@restaurante_escolhido)

    @restaurante_escolhido = (Restaurante.find_by("LOWER(nome) = LOWER(?)", restaurante.squish) if restaurante.present?)
  end

  def catraca_escolhida
    return @catraca_escolhida if defined?(@catraca_escolhida)

    @catraca_escolhida = restaurante_escolhido&.catracas&.find_by(identificador: numero_da_catraca.to_s.strip)
  end

  def validar_restaurante
    if restaurante.blank?
      errors.add(:restaurante, "Informe o restaurante")
    elsif restaurante_escolhido.nil?
      errors.add(:restaurante, "Restaurante não encontrado")
    end
  end

  def validar_catraca
    if numero_da_catraca.blank?
      errors.add(:numero_da_catraca, "Informe o número da catraca")
    elsif !numero_da_catraca.strip.match?(Catraca::IDENTIFICADOR)
      errors.add(:numero_da_catraca, "O número da catraca deve ter 2 dígitos")
    elsif restaurante_escolhido && catraca_escolhida.nil?
      errors.add(:numero_da_catraca, "Catraca não encontrada neste restaurante")
    end
  end
end
