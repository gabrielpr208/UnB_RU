module Controle
  # Logo após o login, o funcionário escolhe o restaurante e a catraca em que vai operar. Pode voltar aqui para
  # trocar de catraca: o ponto anterior é encerrado.
  class PontosAcessoController < BaseController
    before_action :carregar_opcoes

    def new
      @configuracao = ConfiguracaoPontoAcesso.new
    end

    def create
      @configuracao = ConfiguracaoPontoAcesso.new(dados_do_ponto_acesso)
      @configuracao.funcionario = Current.usuario.funcionario

      if @configuracao.save
        redirect_to controle_path, notice: "Configuração do ponto de acesso bem-sucedida"
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def carregar_opcoes
      @ponto_acesso_atual = Current.usuario.funcionario.ponto_acesso_atual
      @restaurantes = Restaurante.em_ordem
    end

    def dados_do_ponto_acesso
      params.expect(configuracao_ponto_acesso: [ :restaurante, :numero_da_catraca ])
    end
  end
end
