# Estudante da UnB, que entra no Portal do Estudante com a matrícula e paga as refeições com o saldo.
class Estudante < ApplicationRecord
  include EspecializacaoDeUsuario

  has_many :recargas, dependent: :destroy
  has_many :acessos, dependent: :destroy

  normalizes :matricula, with: ->(matricula) { matricula.strip }

  validates :matricula, presence: { message: "A matrícula é obrigatória" }
  validates :matricula, format: { with: /\A\d*\z/, message: "A matrícula deve conter apenas números" },
                        allow_blank: true
  validates :matricula, length: { is: 9, message: "A matrícula deve conter 9 dígitos" },
                        allow_blank: true,
                        if: -> { matricula.to_s.match?(/\A\d+\z/) }
  validates :matricula, uniqueness: { message: "Esta matrícula já está cadastrada" }, allow_blank: true

  validates :saldo, numericality: { greater_than_or_equal_to: 0 }

  # Autentica o estudante pela matrícula e senha (ver EspecializacaoDeUsuario::ClassMethods#autenticar_por).
  #
  # Argumentos::
  #   - +matricula+: matrícula digitada.
  #   - +senha+: senha digitada.
  # Retorno::
  #   - o Estudante, se a matrícula existe e a senha confere;
  #   - +nil+ caso contrário.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def self.autenticar(matricula:, senha:)
    autenticar_por(matricula:, senha:)
  end

  # Soma direto no banco (saldo = saldo + valor), sem perder créditos de pagamentos simultâneos.
  def creditar!(valor)
    increment!(:saldo, valor, touch: true)
  end
  def debitar(valor)
    with_lock do
      next false if saldo < valor

      update!(saldo: saldo - valor)
    end
  end
end
