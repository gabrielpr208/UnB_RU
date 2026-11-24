# Estudante e Funcionario especializam Usuario (ver docs/modelo_er.md): a chave primária é a própria
# referência ao usuário, e o login usa um identificador do perfil (matrícula ou SIAPE) com a senha do usuário.
module EspecializacaoDeUsuario
  extend ActiveSupport::Concern

  included do
    self.primary_key = :usuario_id

    belongs_to :usuario

    delegate :nome, :email, to: :usuario
  end

  # Métodos de classe adicionados a quem inclui EspecializacaoDeUsuario.
  module ClassMethods
    private

    # Autentica pelo identificador do perfil e pela senha do usuário. Mesmo quando o identificador não existe,
    # calcula um hash de senha, para que o tempo de resposta não revele quais identificadores estão cadastrados.
    #
    # Argumentos::
    #   - +senha+: senha digitada.
    #   - +identificador+: um único par coluna/valor (ex.: <tt>matricula: "231012345"</tt>).
    # Retorno::
    #   - o registro dono do identificador, se a senha conferir;
    #   - +nil+ se o identificador ou a senha estão em branco, se o identificador não existe ou se a senha
    #     está errada.
    # Efeitos colaterais:: nenhum (apenas consulta o banco).
    def autenticar_por(senha:, **identificador)
      coluna, valor = identificador.sole
      return if valor.blank? || senha.blank?

      registro = includes(:usuario).find_by(coluna => valor.to_s.strip)

      if registro
        registro if registro.usuario.authenticate_senha(senha)
      else
        Usuario.new(senha:)
        nil
      end
    end
  end

  # Primeiro nome do usuário, usado nas saudações das telas.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com a primeira palavra do nome (ex.: <tt>"Maria"</tt> para <tt>"Maria Souza"</tt>).
  # Efeitos colaterais:: nenhum.
  def primeiro_nome
    nome.split.first
  end
end
