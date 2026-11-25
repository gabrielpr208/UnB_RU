# Formulário em que o funcionário, logo após o login, escolhe o ponto de acesso em que vai operar: o restaurante
# (pelo nome) e o número da catraca (2 dígitos). Os dois precisam existir, e a catraca precisa ser do restaurante.
#
# A tela resume qualquer problema como "Ponto de acesso inválido" e mostra o detalhe no campo.
class ConfiguracaoPontoAcesso
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :restaurante, :string
  attribute :numero_da_catraca, :string

  # Funcionário logado que está configurando o ponto de acesso.
  attr_accessor :funcionario
  # PontoAcesso aberto por #save; nil antes de gravar ou se a configuração for inválida.
  attr_reader :ponto_acesso

  validate :validar_restaurante
  validate :validar_catraca

  # Valida a escolha e abre o ponto de acesso do funcionário na catraca escolhida.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - +true+ se o ponto de acesso foi aberto (disponível em #ponto_acesso);
  #   - +false+ se o restaurante ou a catraca são inválidos (os motivos ficam em +errors+).
  # Efeitos colaterais::
  #   cria um PontoAcesso no banco e encerra o ponto anterior do funcionário e o de quem estava na catraca
  #   (ver PontoAcesso.abrir!).
  def save
    return false unless valid?

    @ponto_acesso = PontoAcesso.abrir!(funcionario:, catraca: catraca_escolhida)
    true
  end

  private

  # Busca o restaurante pelo nome digitado. O nome não diferencia maiúsculas de minúsculas, como na regra de
  # nome único do restaurante.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - o Restaurante encontrado;
  #   - +nil+ se o nome está em branco ou não existe. O resultado é memorizado entre as chamadas.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def restaurante_escolhido
    return @restaurante_escolhido if defined?(@restaurante_escolhido)

    @restaurante_escolhido = (Restaurante.find_by("LOWER(nome) = LOWER(?)", restaurante.squish) if restaurante.present?)
  end

  # Busca a catraca pelo número digitado, dentro do restaurante escolhido.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - a Catraca encontrada;
  #   - +nil+ se o restaurante não foi encontrado ou não tem catraca com esse número. O resultado é memorizado
  #     entre as chamadas.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def catraca_escolhida
    return @catraca_escolhida if defined?(@catraca_escolhida)

    @catraca_escolhida = restaurante_escolhido&.catracas&.find_by(identificador: numero_da_catraca.to_s.strip)
  end

  # Validação do restaurante: precisa ser informado e existir.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: adiciona um erro em +restaurante+ quando ele está em branco ou não foi encontrado.
  def validar_restaurante
    if restaurante.blank?
      errors.add(:restaurante, "Informe o restaurante")
    elsif restaurante_escolhido.nil?
      errors.add(:restaurante, "Restaurante não encontrado")
    end
  end

  # Validação do número da catraca (ver #erro_da_catraca).
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: adiciona um erro em +numero_da_catraca+ quando o número é inválido.
  def validar_catraca
    mensagem = erro_da_catraca
    errors.add(:numero_da_catraca, mensagem) if mensagem
  end

  # Confere o número da catraca: precisa ser informado, ter 2 dígitos e existir no restaurante escolhido.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - +String+ com a mensagem de erro;
  #   - +nil+ se o número é válido ou se o restaurante não foi encontrado (esse erro já aparece no restaurante).
  # Efeitos colaterais:: nenhum.
  def erro_da_catraca
    if numero_da_catraca.blank?
      "Informe o número da catraca"
    elsif !numero_da_catraca.strip.match?(Catraca::IDENTIFICADOR)
      "O número da catraca deve ter 2 dígitos"
    elsif restaurante_escolhido && catraca_escolhida.nil?
      "Catraca não encontrada neste restaurante"
    end
  end
end
