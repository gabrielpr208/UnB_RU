module Controle
  class CatracasController < BaseController
    somente_administradores
    before_action :carregar_catraca, only: %i[ edit update destroy ]
    before_action :carregar_restaurantes, only: %i[ new create edit update ]

    def index
      @catracas = Catraca.em_ordem.includes(:restaurante, ponto_acesso_atual: { funcionario: :usuario })
    end

    def new
      @catraca = Catraca.new
    end

    def create
      @catraca = Catraca.new(dados_da_catraca)

      if @catraca.save
        redirect_to controle_catracas_path, notice: "Catraca cadastrada com sucesso"
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @catraca.update(dados_da_catraca)
        redirect_to controle_catracas_path, notice: "Catraca atualizada com sucesso"
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @catraca.remover
        redirect_to controle_catracas_path, notice: "Catraca removida com sucesso", status: :see_other
      else
        redirect_to controle_catracas_path, alert: @catraca.errors[:base].first, status: :see_other
      end
    end

    private

    def carregar_catraca
      @catraca = Catraca.find(params[:id])
    end

    def carregar_restaurantes
      @restaurantes = Restaurante.em_ordem
    end

    def dados_da_catraca
      params.expect(catraca: [ :restaurante_id, :identificador ])
    end
  end
end
