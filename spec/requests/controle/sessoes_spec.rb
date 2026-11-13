require "rails_helper"

RSpec.describe "Login do funcionário", type: :request do
  let!(:funcionario) { criar_funcionario(siape: "1234567") }

  def logar(siape: "1234567", senha: "senha123")
    post login_controle_path, params: { login: { siape:, senha: } }
  end

  describe "GET /controle/login" do
    it "exibe o formulário de login com SIAPE e senha" do
      get login_controle_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Login do funcionário")
      expect(response.body).to include(%(<label class="campo__rotulo" for="login_siape">SIAPE</label>))
      expect(response.body).to include(%(<label class="campo__rotulo" for="login_senha">Senha</label>))
      expect(response.body).to include(%(href="#{login_path}"))
    end

    it "manda o funcionário já logado para a Aplicação de Controle" do
      entrar_como_funcionario(funcionario)
      get login_controle_path

      expect(response).to redirect_to(controle_path)
    end

    it "exibe o formulário para um estudante logado, para que ele possa entrar como funcionário" do
      entrar_como(criar_estudante)
      get login_controle_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Login do funcionário")
    end
  end

  describe "POST /controle/login com dados válidos" do
    it "cria uma sessão para o usuário do funcionário" do
      expect { logar }.to change(funcionario.usuario.sessoes, :count).by(1)
    end

    it "redireciona para a Aplicação de Controle com a mensagem de sucesso" do
      logar

      expect(response).to redirect_to(controle_path)
      expect(flash[:notice]).to eq("Login realizado com sucesso")
    end

    it "mantém o funcionário logado nas próximas requisições" do
      logar
      get controle_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Olá, Funcionário")
    end

    it "volta para a página da Aplicação de Controle que o funcionário tentou acessar antes do login" do
      get controle_path(origem: "teste")
      logar

      expect(response).to redirect_to(controle_url(origem: "teste"))
    end

    it "não volta para uma página do estudante guardada antes do login" do
      get root_path
      logar

      expect(response).to redirect_to(controle_path)
    end

    it "encerra a sessão de estudante aberta no mesmo navegador" do
      estudante = criar_estudante
      entrar_como(estudante)

      expect { logar }.to change(estudante.usuario.sessoes, :count).by(-1)
                      .and change(funcionario.usuario.sessoes, :count).by(1)
    end
  end

  describe "POST /controle/login com dados inválidos" do
    {
      "SIAPE com 6 dígitos" => { siape: "123456" },
      "SIAPE com 8 dígitos" => { siape: "12345678" },
      "SIAPE com letras" => { siape: "123A567" },
      "SIAPE em branco" => { siape: "" },
      "senha errada" => { senha: "senha321" },
      "senha em branco" => { senha: "" },
      "SIAPE inexistente" => { siape: "7654321" }
    }.each do |caso, dados|
      context "com #{caso}" do
        it "não cria sessão e exibe a mensagem genérica de erro" do
          expect { logar(**dados) }.not_to change(Sessao, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Erro na autenticação. Verifique os dados")
        end
      end
    end

    it "recusa a matrícula e a senha de um estudante" do
      criar_estudante(matricula: "231012345")
      logar(siape: "231012345")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Erro na autenticação. Verifique os dados")
    end

    it "mantém o SIAPE digitado, mas não a senha" do
      logar(senha: "senha321")

      expect(response.body).to include('value="1234567"')
      expect(response.body).not_to include("senha321")
    end

    it "não dá acesso à Aplicação de Controle" do
      logar(senha: "senha321")
      get controle_path

      expect(response).to redirect_to(login_controle_path)
    end
  end

  describe "POST /controle/login sem os dados do formulário" do
    it "responde 400" do
      post login_controle_path, params: {}

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "login de estudante com o SIAPE do funcionário" do
    it "é recusado no Portal do Estudante" do
      post login_path, params: { login: { matricula: "1234567", senha: "senha123" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Sessao.count).to eq(0)
    end
  end

  describe "DELETE /controle/logout" do
    before { entrar_como_funcionario(funcionario) }

    it "apaga a sessão" do
      expect { delete logout_controle_path }.to change(Sessao, :count).by(-1)
    end

    it "redireciona para o login de funcionário com a mensagem de saída" do
      delete logout_controle_path

      expect(response).to redirect_to(login_controle_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq("Você saiu da sua conta")
    end

    it "exige um novo login para acessar a Aplicação de Controle" do
      delete logout_controle_path
      get controle_path

      expect(response).to redirect_to(login_controle_path)
    end
  end
end
