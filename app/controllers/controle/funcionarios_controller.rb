module Controle
  # Cadastro de funcionários pelo administrador (features/cadastro_funcionario.feature).
  class FuncionariosController < BaseController
    somente_administradores

    def index
      @funcionarios = Funcionario.em_ordem.includes(:usuario)
    end

    def new
      @cadastro = CadastroFuncionario.new
    end

    def create
      @cadastro = CadastroFuncionario.new(dados_do_funcionario)

      if @cadastro.save
        redirect_to controle_funcionarios_path, notice: "Funcionário cadastrado com sucesso"
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def dados_do_funcionario
      params.expect(cadastro_funcionario: [ :nome, :siape, :email, :senha, :confirmacao_senha, :administrador ])
    end
  end
end
