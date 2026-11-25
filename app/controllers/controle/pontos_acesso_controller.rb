module Controle
  # Logo após o login, o funcionário escolhe o restaurante e a catraca em que vai operar. Pode voltar aqui para
  # trocar de catraca: o ponto anterior é encerrado.
  class PontosAcessoController < BaseController
    before_action :carregar_opcoes

    # Mostra o formulário de configuração do ponto de acesso em branco.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +new+.
    def new
      @configuracao = ConfiguracaoPontoAcesso.new
    end

    # Abre o ponto de acesso do funcionário logado no restaurante e na catraca escolhidos.
    #
    # Argumentos::
    #   nenhum; os dados vêm de <tt>params[:configuracao_ponto_acesso]</tt> (ver #dados_do_ponto_acesso).
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   com dados válidos, cria o PontoAcesso no banco (encerrando o anterior) e redireciona para a página
    #   inicial com um aviso de sucesso; senão, renderiza o formulário com os erros (status 422).
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

    # Filtro que carrega o ponto de acesso atual do funcionário e os restaurantes oferecidos no formulário.
    #
    # Argumentos:: nenhum.
    # Retorno:: <tt>ActiveRecord::Relation</tt> de Restaurante em ordem de nome.
    # Efeitos colaterais:: define <tt>@ponto_acesso_atual</tt> e <tt>@restaurantes</tt>.
    def carregar_opcoes
      @ponto_acesso_atual = Current.usuario.funcionario.ponto_acesso_atual
      @restaurantes = Restaurante.em_ordem
    end

    # Dados permitidos do formulário de ponto de acesso.
    #
    # Argumentos:: nenhum.
    # Retorno:: <tt>ActionController::Parameters</tt> com +restaurante+ e +numero_da_catraca+.
    # Efeitos colaterais:: responde 400 (Bad Request) se os parâmetros não tiverem o formato esperado.
    def dados_do_ponto_acesso
      params.expect(configuracao_ponto_acesso: [ :restaurante, :numero_da_catraca ])
    end
  end
end
