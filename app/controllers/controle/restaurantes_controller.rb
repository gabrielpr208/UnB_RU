module Controle
  class RestaurantesController < BaseController
    somente_administradores
    before_action :carregar_restaurante, only: %i[ edit update destroy ]

    def index
      @restaurantes = Restaurante.em_ordem
    end

    def new
      @restaurante = Restaurante.new
    end

    def create
      @restaurante = Restaurante.new(dados_do_restaurante)

      if @restaurante.save
        redirect_to controle_restaurantes_path, notice: "Restaurante cadastrado com sucesso"
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @restaurante.update(dados_do_restaurante)
        redirect_to controle_restaurantes_path, notice: "Restaurante atualizado com sucesso"
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @restaurante.remover
        redirect_to controle_restaurantes_path, notice: "Restaurante removido com sucesso", status: :see_other
      else
        redirect_to controle_restaurantes_path, alert: @restaurante.errors[:base].first, status: :see_other
      end
    end

    private

    def carregar_restaurante
      @restaurante = Restaurante.find(params[:id])
    end

    def dados_do_restaurante
      params.expect(restaurante: [ :nome, :campus ])
    end
  end
end
