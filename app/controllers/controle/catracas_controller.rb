module Controle
  # Gestão das catracas dos restaurantes pelo administrador.
  class CatracasController < BaseController
    somente_administradores
    before_action :carregar_catraca, only: %i[ edit update destroy ]
    before_action :carregar_restaurantes, only: %i[ new create edit update ]

    # Lista as catracas, com o restaurante e o funcionário que está operando cada uma.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +index+.
    def index
      @catracas = Catraca.em_ordem.includes(:restaurante, ponto_acesso_atual: { funcionario: :usuario })
    end

    # Mostra o formulário de cadastro de catraca em branco.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +new+.
    def new
      @catraca = Catraca.new
    end

    # Cadastra uma catraca com os dados do formulário.
    #
    # Argumentos:: nenhum; os dados vêm de <tt>params[:catraca]</tt> (ver #dados_da_catraca).
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   com dados válidos, cria a Catraca no banco e redireciona para a lista com um aviso de sucesso; senão,
    #   renderiza o formulário com os erros (status 422).
    def create
      @catraca = Catraca.new(dados_da_catraca)

      if @catraca.save
        redirect_to controle_catracas_path, notice: "Catraca cadastrada com sucesso"
      else
        render :new, status: :unprocessable_content
      end
    end

    # Mostra o formulário de edição da catraca.
    #
    # Argumentos:: nenhum; a catraca vem de <tt>params[:id]</tt> (ver #carregar_catraca).
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +edit+.
    def edit
    end

    # Altera a catraca com os dados do formulário.
    #
    # Argumentos::
    #   nenhum; a catraca vem de <tt>params[:id]</tt> e os dados, de <tt>params[:catraca]</tt>.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   com dados válidos, atualiza a Catraca no banco e redireciona para a lista com um aviso de sucesso; senão,
    #   renderiza o formulário com os erros (status 422).
    def update
      if @catraca.update(dados_da_catraca)
        redirect_to controle_catracas_path, notice: "Catraca atualizada com sucesso"
      else
        render :edit, status: :unprocessable_content
      end
    end

    # Remove a catraca, se ela não estiver em uso nem tiver acessos (ver Catraca#remover).
    #
    # Argumentos:: nenhum; a catraca vem de <tt>params[:id]</tt>.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   apaga a catraca do banco quando permitido e redireciona para a lista com um aviso de sucesso ou com o
    #   motivo da recusa.
    def destroy
      if @catraca.remover
        redirect_to controle_catracas_path, notice: "Catraca removida com sucesso", status: :see_other
      else
        redirect_to controle_catracas_path, alert: @catraca.errors[:base].first, status: :see_other
      end
    end

    private

    # Filtro que carrega a catraca indicada na URL.
    #
    # Argumentos:: nenhum; usa <tt>params[:id]</tt>.
    # Retorno:: a Catraca encontrada.
    # Efeitos colaterais:: define <tt>@catraca</tt>; responde 404 se a catraca não existe.
    def carregar_catraca
      @catraca = Catraca.find(params[:id])
    end

    # Filtro que carrega os restaurantes oferecidos no formulário.
    #
    # Argumentos:: nenhum.
    # Retorno:: <tt>ActiveRecord::Relation</tt> de Restaurante em ordem de nome.
    # Efeitos colaterais:: define <tt>@restaurantes</tt>.
    def carregar_restaurantes
      @restaurantes = Restaurante.em_ordem
    end

    # Dados permitidos do formulário de catraca.
    #
    # Argumentos:: nenhum.
    # Retorno:: <tt>ActionController::Parameters</tt> com +restaurante_id+ e +identificador+.
    # Efeitos colaterais:: responde 400 (Bad Request) se os parâmetros não tiverem o formato esperado.
    def dados_da_catraca
      params.expect(catraca: [ :restaurante_id, :identificador ])
    end
  end
end
