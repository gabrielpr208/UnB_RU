require "rails_helper"

RSpec.describe "Cadastro de estudante", type: :request do
  def cadastrar(**alteracoes)
    post cadastro_path, params: { cadastro_estudante: dados_validos_de_cadastro(**alteracoes) }
  end

  describe "GET /cadastro" do
    before { get cadastro_path }

    it "exibe o formulário de cadastro" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Criar conta de acesso")
    end

    it "tem um campo rotulado para cada dado do estudante" do
      {
        "nome" => "Nome completo",
        "matricula" => "Matrícula",
        "email" => "E-mail",
        "senha" => "Senha",
        "confirmacao_senha" => "Confirmação de senha"
      }.each do |campo, rotulo|
        expect(response.body).to include(%(<label class="campo__rotulo" for="cadastro_estudante_#{campo}">#{rotulo}</label>))
      end
    end

    it "deixa a validação a cargo do servidor" do
      expect(response.body).to match(/<form[^>]+novalidate/)
      expect(response.body).not_to include("maxlength")
    end

    it "destaca a aba \"Criar conta\"" do
      expect(response.body).to include(%(class="abas__item abas__item--ativa" aria-current="page" href="#{cadastro_path}"))
    end
  end

  describe "GET /cadastro com um estudante logado" do
    it "manda para a página inicial" do
      entrar_como(criar_estudante)
      get cadastro_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /cadastro com dados válidos" do
    it "cria o estudante" do
      expect { cadastrar }.to change(Estudante, :count).by(1)
    end

    it "redireciona para a página de login com a mensagem de sucesso" do
      cadastrar

      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to eq("Cadastro realizado com sucesso")

      follow_redirect!
      expect(response.body).to include("Cadastro realizado com sucesso")
    end

    it "ignora atributos que não fazem parte do formulário" do
      post cadastro_path, params: { cadastro_estudante: dados_validos_de_cadastro.merge(saldo: "1000") }

      expect(Estudante.find_by!(matricula: "231012345").saldo).to eq(0)
    end
  end

  describe "POST /cadastro com dados inválidos" do
    {
      "matrícula com 8 dígitos" => [ { matricula: "23101234" }, "A matrícula deve conter 9 dígitos" ],
      "matrícula com 10 dígitos" => [ { matricula: "2310123456" }, "A matrícula deve conter 9 dígitos" ],
      "matrícula com letras" => [ { matricula: "23A012345" }, "A matrícula deve conter apenas números" ],
      "matrícula em branco" => [ { matricula: "" }, "A matrícula é obrigatória" ],
      "confirmação de senha diferente" => [ { confirmacao_senha: "outra456" }, "A confirmação de senha não confere" ]
    }.each do |caso, (alteracoes, mensagem)|
      context "com #{caso}" do
        it "não cria a conta e exibe \"#{mensagem}\"" do
          expect { cadastrar(**alteracoes) }.not_to change(Usuario, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(mensagem)
          expect(response.body).to include("Não foi possível concluir o cadastro")
        end
      end
    end

    context "com matrícula já cadastrada" do
      before { criar_estudante(matricula: "231012345") }

      it "não cria a conta e exibe a mensagem de duplicidade" do
        expect { cadastrar }.not_to change(Usuario, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Esta matrícula já está cadastrada")
      end
    end

    it "mantém os dados digitados, exceto as senhas" do
      cadastrar(matricula: "23A012345")

      expect(response.body).to include('value="Maria Souza"')
      expect(response.body).to include('value="23A012345"')
      expect(response.body).to include('value="maria@aluno.unb.br"')
      expect(response.body).not_to include('value="senha123"')
    end

    it "marca o campo com erro como inválido para leitores de tela" do
      cadastrar(matricula: "23A012345")

      expect(response.body).to include('aria-invalid="true"')
      expect(response.body).to include('aria-describedby="cadastro_estudante_matricula_mensagem"')
    end

    it "mantém a aba \"Criar conta\" destacada" do
      cadastrar(matricula: "")

      expect(response.body).to include("abas__item--ativa\" aria-current=\"page\" href=\"#{cadastro_path}\"")
    end
  end

  describe "POST /cadastro sem os dados do formulário" do
    it "responde 400" do
      post cadastro_path, params: {}

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "registro em log" do
    it "não grava as senhas" do
      filtro = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      filtrados = filtro.filter("cadastro_estudante" => dados_validos_de_cadastro.stringify_keys)

      expect(filtrados["cadastro_estudante"]).to include(
        "senha" => "[FILTERED]",
        "confirmacao_senha" => "[FILTERED]"
      )
    end
  end
end
