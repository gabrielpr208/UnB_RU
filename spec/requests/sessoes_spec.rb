require "rails_helper"

RSpec.describe "Login do estudante", type: :request do
  let!(:estudante) { criar_estudante(matricula: "231012345") }

  def logar(matricula: "231012345", senha: "senha123")
    post login_path, params: { login: { matricula:, senha: } }
  end

  describe "GET /login" do
    it "exibe o formulário de login" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Login do estudante")
      expect(response.body).to include(%(<label class="campo__rotulo" for="login_matricula">Matrícula</label>))
      expect(response.body).to include(%(<label class="campo__rotulo" for="login_senha">Senha</label>))
      expect(response.body).to include(%(href="#{cadastro_path}"))
      expect(response.body).to include(%(href="#{login_controle_path}"))
    end

    it "manda quem já está logado para a página inicial" do
      entrar_como(estudante)
      get login_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /login com dados válidos" do
    it "cria uma sessão para o usuário" do
      expect { logar }.to change(estudante.usuario.sessoes, :count).by(1)
    end

    it "guarda o IP e o navegador da sessão" do
      post login_path, params: { login: { matricula: "231012345", senha: "senha123" } },
                       headers: { "User-Agent" => "Firefox/140.0" }

      sessao = estudante.usuario.sessoes.last
      expect(sessao.endereco_ip).to eq("127.0.0.1")
      expect(sessao.user_agent).to eq("Firefox/140.0")
    end

    it "redireciona para a página inicial com a mensagem de sucesso" do
      logar

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Login realizado com sucesso")
    end

    it "mantém o estudante logado nas próximas requisições" do
      logar
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Olá, Estudante")
    end

    it "volta para a página que o estudante tentou acessar antes do login" do
      get root_path(origem: "teste")
      logar

      expect(response).to redirect_to(root_path(origem: "teste"))
    end

    it "não volta para uma página da Aplicação de Controle guardada antes do login" do
      get controle_path
      logar

      expect(response).to redirect_to(root_path)
    end

    it "encerra a sessão de funcionário aberta no mesmo navegador" do
      funcionario = criar_funcionario
      entrar_como_funcionario(funcionario)

      expect { logar }.to change(funcionario.usuario.sessoes, :count).by(-1)
                      .and change(estudante.usuario.sessoes, :count).by(1)
    end
  end

  describe "POST /login com dados inválidos" do
    {
      "senha errada" => { senha: "senha321" },
      "matrícula inexistente" => { matricula: "231012346" },
      "matrícula com letras" => { matricula: "23101234A" },
      "matrícula em branco" => { matricula: "" },
      "senha em branco" => { senha: "" }
    }.each do |caso, dados|
      context "com #{caso}" do
        it "não cria sessão e exibe a mensagem genérica de erro" do
          expect { logar(**dados) }.not_to change(Sessao, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Erro na autenticação. Verifique os dados")
        end
      end
    end

    it "mantém a matrícula digitada, mas não a senha" do
      logar(senha: "senha321")

      expect(response.body).to include('value="231012345"')
      expect(response.body).not_to include("senha321")
    end

    it "não deixa o estudante logado" do
      logar(senha: "senha321")
      get root_path

      expect(response).to redirect_to(login_path)
    end
  end

  describe "POST /login sem os dados do formulário" do
    it "responde 400" do
      post login_path, params: {}

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /logout" do
    before { entrar_como(estudante) }

    it "apaga a sessão" do
      expect { delete logout_path }.to change(Sessao, :count).by(-1)
    end

    it "redireciona para o login com a mensagem de saída" do
      delete logout_path

      expect(response).to redirect_to(login_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq("Você saiu da sua conta")
    end

    it "exige um novo login para acessar as páginas do estudante" do
      delete logout_path
      get root_path

      expect(response).to redirect_to(login_path)
    end
  end

  describe "DELETE /logout de quem não é estudante" do
    it "também encerra a sessão de um funcionário" do
      entrar_como_funcionario(criar_funcionario)

      expect { delete logout_path }.to change(Sessao, :count).by(-1)
      expect(response).to redirect_to(login_path)
    end
  end

  describe "cookie de sessão" do
    it "é ignorado se não for assinado pelo servidor" do
      entrar_como(estudante)
      cookies[:sessao_id] = estudante.usuario.sessoes.last.id.to_s
      get root_path

      expect(response).to redirect_to(login_path)
    end

    it "deixa de valer quando a sessão é apagada no banco" do
      entrar_como(estudante)
      Sessao.delete_all
      get root_path

      expect(response).to redirect_to(login_path)
    end
  end

  describe "registro em log" do
    it "não grava a senha" do
      filtro = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

      expect(filtro.filter("login" => { "senha" => "senha123" })["login"]["senha"]).to eq("[FILTERED]")
    end
  end
end
