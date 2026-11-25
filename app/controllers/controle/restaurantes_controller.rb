module Controle
  # Gestão dos restaurantes pelo administrador.
  class RestaurantesController < BaseController
    somente_administradores
    before_action :carregar_restaurante, only: %i[ edit update destroy ]

    # Lista os restaurantes em ordem de nome.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +index+.
    def index
      @restaurantes = Restaurante.em_ordem
    end

    # Mostra o formulário de cadastro de restaurante em branco.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +new+.
    def new
      @restaurante = Restaurante.new
    end

    # Cadastra um restaurante com os dados do formulário.
    #
    # Argumentos:: nenhum; os dados vêm de <tt>params[:restaurante]</tt> (ver #dados_do_restaurante).
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   com dados válidos, cria o Restaurante no banco e redireciona para a lista com um aviso de sucesso;
    #   senão, renderiza o formulário com os erros (status 422).
    def create
      @restaurante = Restaurante.new(dados_do_restaurante)

      if @restaurante.save
        redirect_to controle_restaurantes_path, notice: "Restaurante cadastrado com sucesso"
      else
        render :new, status: :unprocessable_content
      end
    end

    # Mostra o formulário de edição do restaurante.
    #
    # Argumentos:: nenhum; o restaurante vem de <tt>params[:id]</tt> (ver #carregar_restaurante).
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +edit+.
    def edit
    end

    # Altera o restaurante com os dados do formulário.
    #
    # Argumentos::
    #   nenhum; o restaurante vem de <tt>params[:id]</tt> e os dados, de <tt>params[:restaurante]</tt>.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   com dados válidos, atualiza o Restaurante no banco e redireciona para a lista com um aviso de sucesso;
    #   senão, renderiza o formulário com os erros (status 422).
    def update
      if @restaurante.update(dados_do_restaurante)
        redirect_to controle_restaurantes_path, notice: "Restaurante atualizado com sucesso"
      else
        render :edit, status: :unprocessable_content
      end
    end

    # Remove o restaurante, se ele não tiver catracas (ver Restaurante#remover).
    #
    # Argumentos:: nenhum; o restaurante vem de <tt>params[:id]</tt>.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   apaga o restaurante do banco quando permitido e redireciona para a lista com um aviso de sucesso ou com
    #   o motivo da recusa.
    def destroy
      if @restaurante.remover
        redirect_to controle_restaurantes_path, notice: "Restaurante removido com sucesso", status: :see_other
      else
        redirect_to controle_restaurantes_path, alert: @restaurante.errors[:base].first, status: :see_other
      end
    end

    private

    # Filtro que carrega o restaurante indicado na URL.
    #
    # Argumentos:: nenhum; usa <tt>params[:id]</tt>.
    # Retorno:: o Restaurante encontrado.
    # Efeitos colaterais:: define <tt>@restaurante</tt>; responde 404 se o restaurante não existe.
    def carregar_restaurante
      @restaurante = Restaurante.find(params[:id])
    end

    # Dados permitidos do formulário de restaurante.
    #
    # Argumentos:: nenhum.
    # Retorno:: <tt>ActionController::Parameters</tt> com +nome+ e +campus+.
    # Efeitos colaterais:: responde 400 (Bad Request) se os parâmetros não tiverem o formato esperado.
    def dados_do_restaurante
      params.expect(restaurante: [ :nome, :campus ])
    end
  end
end
