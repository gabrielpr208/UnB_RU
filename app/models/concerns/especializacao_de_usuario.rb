# Estudante e Funcionario especializam Usuario (ver docs/modelo_er.md): a chave primária é a própria
# referência ao usuário, e o login usa um identificador do perfil (matrícula ou SIAPE) com a senha do usuário.
module EspecializacaoDeUsuario
  extend ActiveSupport::Concern

  included do
    self.primary_key = :usuario_id

    belongs_to :usuario

    delegate :nome, :email, to: :usuario
  end

  class_methods do
    private

    # Devolve o registro dono do identificador (ex.: matricula: "231012345") se a senha conferir; nil caso contrário.
    def autenticar_por(senha:, **identificador)
      coluna, valor = identificador.sole
      return if valor.blank? || senha.blank?

      registro = includes(:usuario).find_by(coluna => valor.to_s.strip)

      if registro
        registro if registro.usuario.authenticate_senha(senha)
      else
        # Calcula um hash mesmo assim, para que o tempo de resposta não revele quais identificadores existem.
        Usuario.new(senha:)
        nil
      end
    end
  end

  def primeiro_nome
    nome.split.first
  end
end
