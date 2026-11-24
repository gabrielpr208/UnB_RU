module Controle
  # Gestão de funcionários pelo administrador
  # (features/cadastro_funcionario.feature e features/gerencia_funcionarios.feature).
  class FuncionariosController < BaseController
    somente_administradores
    before_action :carregar_funcionario, only: %i[ edit update destroy ]

    # Lista os funcionários em ordem de nome.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +index+.
    def index
      @funcionarios = Funcionario.em_ordem.includes(:usuario)
      @funcionario_logado = Current.usuario.funcionario
    end

    # Mostra o formulário de cadastro de funcionário em branco.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +new+.
    def new
      @cadastro = CadastroFuncionario.new
    end

    # Cadastra um funcionário com os dados do formulário.
    #
    # Argumentos:: nenhum; os dados vêm de <tt>params[:cadastro_funcionario]</tt> (ver #dados_do_funcionario).
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   com dados válidos, cria o Usuario e o Funcionario no banco e redireciona para a lista com um aviso de
    #   sucesso; senão, renderiza o formulário com os erros (status 422).
    def create
      @cadastro = CadastroFuncionario.new(dados_do_funcionario)

      if @cadastro.save
        redirect_to controle_funcionarios_path, notice: "Funcionário cadastrado com sucesso"
      else
        render :new, status: :unprocessable_content
      end
    end

    # Mostra o formulário de edição, preenchido com os dados atuais do funcionário.
    #
    # Argumentos:: nenhum; o funcionário vem de <tt>params[:id]</tt> (ver #carregar_funcionario).
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +edit+.
    def edit
      @cadastro = CadastroFuncionario.editar(@funcionario, responsavel: Current.usuario.funcionario)
    end

    # Altera o funcionário com os dados do formulário. Senha em branco mantém a senha atual.
    #
    # Argumentos::
    #   nenhum; o funcionário vem de <tt>params[:id]</tt> e os dados, de <tt>params[:cadastro_funcionario]</tt>.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   com dados válidos, atualiza o Usuario e o Funcionario no banco e redireciona para a lista com um aviso
    #   de sucesso; senão, renderiza o formulário com os erros (status 422).
    def update
      @cadastro = CadastroFuncionario.editar(@funcionario, responsavel: Current.usuario.funcionario)
      @cadastro.assign_attributes(dados_do_funcionario)

      if @cadastro.save
        redirect_to controle_funcionarios_path, notice: "Funcionário atualizado com sucesso"
      else
        render :edit, status: :unprocessable_content
      end
    end

    # Remove o funcionário e a conta dele, a não ser que seja o próprio administrador logado
    # (ver Funcionario#remover).
    #
    # Argumentos:: nenhum; o funcionário vem de <tt>params[:id]</tt>.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   apaga do banco o usuário, o funcionário, as sessões e os pontos de acesso dele quando permitido, e
    #   redireciona para a lista com um aviso de sucesso ou com o motivo da recusa.
    def destroy
      if @funcionario.remover(responsavel: Current.usuario.funcionario)
        redirect_to controle_funcionarios_path, notice: "Funcionário removido com sucesso", status: :see_other
      else
        redirect_to controle_funcionarios_path, alert: @funcionario.errors[:base].first, status: :see_other
      end
    end

    private

    # Filtro que carrega o funcionário indicado na URL, já com o usuário dele.
    #
    # Argumentos:: nenhum; usa <tt>params[:id]</tt>.
    # Retorno:: o Funcionario encontrado.
    # Efeitos colaterais:: define <tt>@funcionario</tt>; responde 404 se o funcionário não existe.
    def carregar_funcionario
      @funcionario = Funcionario.includes(:usuario).find(params[:id])
    end

    # Dados permitidos do formulário de funcionário.
    #
    # Argumentos:: nenhum.
    # Retorno::
    #   <tt>ActionController::Parameters</tt> com nome, SIAPE, e-mail, senha, confirmação e se é administrador.
    # Efeitos colaterais:: responde 400 (Bad Request) se os parâmetros não tiverem o formato esperado.
    def dados_do_funcionario
      params.expect(cadastro_funcionario: [ :nome, :siape, :email, :senha, :confirmacao_senha, :administrador ])
    end
  end
end
