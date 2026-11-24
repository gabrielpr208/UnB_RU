# Funcionário do RU, que entra na Aplicação de Controle com o SIAPE (equivalente à matrícula) e a senha.
class Funcionario < ApplicationRecord
  include EspecializacaoDeUsuario

  # Quantidade de dígitos do SIAPE.
  TAMANHO_DO_SIAPE = 7

  has_many :pontos_acesso, dependent: :destroy

  ##
  # :method: ponto_acesso_atual
  # Ponto de acesso em que o funcionário está operando agora.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - o PontoAcesso em aberto;
  #   - +nil+ se o funcionário ainda não escolheu uma catraca.
  # Efeitos colaterais:: nenhum.
  has_one :ponto_acesso_atual, -> { em_aberto }, class_name: "PontoAcesso"

  normalizes :siape, with: ->(siape) { siape.strip }

  validates :siape, presence: { message: "O SIAPE é obrigatório" }
  validates :siape, format: { with: /\A\d*\z/, message: "O SIAPE deve conter apenas números" },
                    allow_blank: true
  validates :siape, length: { is: TAMANHO_DO_SIAPE, message: "O SIAPE deve conter #{TAMANHO_DO_SIAPE} dígitos" },
                    allow_blank: true,
                    if: -> { siape.to_s.match?(/\A\d+\z/) }
  validates :siape, uniqueness: { message: "Este SIAPE já está cadastrado" }, allow_blank: true

  ##
  # :singleton-method: em_ordem
  # Ordena os funcionários pelo nome e, em caso de empate, pelo SIAPE.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>ActiveRecord::Relation</tt> de Funcionario, já com o +join+ em +usuarios+.
  # Efeitos colaterais:: nenhum.
  scope :em_ordem, -> { joins(:usuario).order("usuarios.nome", :siape) }

  # Autentica o funcionário pelo SIAPE e senha (ver EspecializacaoDeUsuario::ClassMethods#autenticar_por).
  #
  # Argumentos::
  #   - +siape+: SIAPE digitado.
  #   - +senha+: senha digitada.
  # Retorno::
  #   - o Funcionario, se o SIAPE existe e a senha confere;
  #   - +nil+ caso contrário.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def self.autenticar(siape:, senha:)
    autenticar_por(siape:, senha:)
  end

  # Encerra o ponto de acesso em aberto do funcionário, deixando a catraca livre.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Integer+ com a quantidade de pontos encerrados (+0+ se não havia ponto em aberto).
  # Efeitos colaterais:: preenche +encerrado_em+ dos pontos em aberto do funcionário no banco.
  def encerrar_ponto_acesso
    pontos_acesso.encerrar
  end

  # Remove o funcionário junto com a conta de usuário dele. Os acessos registrados ficam, porque pertencem à
  # catraca. Ninguém remove a própria conta: assim sempre sobra ao menos um administrador.
  #
  # Argumentos::
  #   - +responsavel+: Funcionario logado que está pedindo a remoção.
  # Retorno::
  #   - o Usuario removido, quando a remoção dá certo;
  #   - +false+ quando o responsável tenta remover a própria conta.
  # Efeitos colaterais::
  #   apaga do banco o usuário, o funcionário, as sessões abertas e os pontos de acesso dele: ele sai da
  #   Aplicação de Controle e a catraca que operava fica livre. Na recusa, nada é apagado e o motivo fica em
  #   <tt>errors[:base]</tt>.
  def remover(responsavel:)
    if responsavel == self
      errors.add(:base, "Você não pode remover a sua própria conta")
      false
    else
      usuario.destroy
    end
  end
end
