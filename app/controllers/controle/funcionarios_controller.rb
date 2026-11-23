module Controle
  # Gestão de funcionários pelo administrador
  # (features/cadastro_funcionario.feature e features/gerencia_funcionarios.feature).
  class FuncionariosController < BaseController
    somente_administradores
    before_action :carregar_funcionario, only: %i[ edit update destroy ]

    def index
      @funcionarios = Funcionario.em_ordem.includes(:usuario)
      @funcionario_logado = Current.usuario.funcionario
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

    def edit
      @cadastro = CadastroFuncionario.editar(@funcionario, responsavel: Current.usuario.funcionario)
    end

    def update
      @cadastro = CadastroFuncionario.editar(@funcionario, responsavel: Current.usuario.funcionario)
      @cadastro.assign_attributes(dados_do_funcionario)

      if @cadastro.save
        redirect_to controle_funcionarios_path, notice: "Funcionário atualizado com sucesso"
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @funcionario.remover(responsavel: Current.usuario.funcionario)
        redirect_to controle_funcionarios_path, notice: "Funcionário removido com sucesso", status: :see_other
      else
        redirect_to controle_funcionarios_path, alert: @funcionario.errors[:base].first, status: :see_other
      end
    end

    private

    def carregar_funcionario
      @funcionario = Funcionario.includes(:usuario).find(params[:id])
    end

    def dados_do_funcionario
      params.expect(cadastro_funcionario: [ :nome, :siape, :email, :senha, :confirmacao_senha, :administrador ])
    end
  end
end
