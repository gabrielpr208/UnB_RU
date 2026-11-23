require "rails_helper"

RSpec.describe "Cadastro de funcionários", type: :request do
  let!(:administrador) { criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true) }

  def html
    Nokogiri::HTML5(response.body)
  end

  def siapes_na_lista
    html.css("#funcionarios tbody tr td:nth-child(2)").map { |celula| celula.text.strip }
  end

  def erro_do_campo(atributo)
    html.at("#cadastro_funcionario_#{atributo}_mensagem.campo__erro")&.text&.strip
  end

  def dados_validos(**alteracoes)
    { nome: "Carlos Dias", siape: "1112223", email: "carlos@unb.br",
      senha: "senha123", confirmacao_senha: "senha123" }.merge(alteracoes)
  end

  describe "acesso" do
    it "pede login a quem não está logado" do
      get controle_funcionarios_path

      expect(response).to redirect_to(login_controle_path)
    end

    it "não deixa estudante entrar" do
      entrar_como(criar_estudante)
      get new_controle_funcionario_path

      expect(response).to redirect_to(login_controle_path)
      expect(flash[:alert]).to eq("Acesso por estudantes não autorizado")
    end

    it "não deixa funcionário que não é administrador ver a lista nem cadastrar" do
      entrar_como_funcionario(criar_funcionario(siape: "1234567"))

      get controle_funcionarios_path
      expect(response).to redirect_to(controle_path)
      expect(flash[:alert]).to eq("Acesso permitido apenas para administradores")

      expect { post controle_funcionarios_path, params: { cadastro_funcionario: dados_validos(administrador: "true") } }
        .not_to change(Funcionario, :count)
      expect(response).to redirect_to(controle_path)
    end
  end

  context "como administrador" do
    before { entrar_como_funcionario(administrador) }

    describe "lista" do
      it "mostra os funcionários em ordem de nome, com SIAPE, e-mail e perfil" do
        usuario = Usuario.create!(nome: "Bruno Alves", email: "bruno@unb.br", senha: "senha123")
        Funcionario.create!(usuario:, siape: "2223334")

        get controle_funcionarios_path

        expect(response).to have_http_status(:ok)
        expect(html.css("#funcionarios tbody tr td:first-child").map(&:text)).to eq([ "Bruno Alves", "Funcionário Existente" ])
        expect(html.css("#funcionarios tbody tr").map { |linha| linha.css("td").map { |c| c.text.strip } }).to eq([
          [ "Bruno Alves", "2223334", "bruno@unb.br", "Funcionário" ],
          [ "Funcionário Existente", "7654321", "admin@unb.br", "Administrador" ]
        ])
      end

      it "marca a aba Funcionários como ativa" do
        get controle_funcionarios_path

        expect(html.css(".abas__item--ativa").map(&:text)).to eq([ "Funcionários" ])
      end
    end

    describe "formulário" do
      it "mostra os campos, com o perfil Funcionário marcado" do
        get new_controle_funcionario_path

        expect(response).to have_http_status(:ok)
        %w[ nome siape email senha confirmacao_senha ].each do |campo|
          expect(html.at("input#cadastro_funcionario_#{campo}")).to be_present
        end
        expect(html.at("input#cadastro_funcionario_administrador_false")["checked"]).to be_present
        expect(html.at("input#cadastro_funcionario_administrador_true")["checked"]).to be_nil
      end
    end

    describe "cadastro" do
      it "cadastra funcionário comum e volta para a lista com a mensagem de sucesso" do
        expect do
          post controle_funcionarios_path, params: { cadastro_funcionario: dados_validos(administrador: "false") }
        end.to change(Funcionario, :count).by(1)

        expect(response).to redirect_to(controle_funcionarios_path)
        expect(flash[:notice]).to eq("Funcionário cadastrado com sucesso")
        expect(Funcionario.find_by!(siape: "1112223")).to have_attributes(nome: "Carlos Dias", administrador: false)
      end

      it "cadastra administrador" do
        post controle_funcionarios_path, params: { cadastro_funcionario: dados_validos(administrador: "true") }

        expect(Funcionario.find_by!(siape: "1112223")).to be_administrador
      end

      it "o funcionário cadastrado consegue entrar na Aplicação de Controle" do
        post controle_funcionarios_path, params: { cadastro_funcionario: dados_validos }
        delete logout_controle_path

        post login_controle_path, params: { login: { siape: "1112223", senha: "senha123" } }

        expect(response).to redirect_to(controle_path)
      end

      {
        { siape: "123" } => [ :siape, "O SIAPE deve conter 7 dígitos" ],
        { siape: "7654321" } => [ :siape, "Este SIAPE já está cadastrado" ],
        { email: "admin@unb.br" } => [ :email, "Este e-mail já está cadastrado" ],
        { nome: "" } => [ :nome, "O nome é obrigatório" ],
        { confirmacao_senha: "outra456" } => [ :confirmacao_senha, "A confirmação de senha não confere" ]
      }.each do |alteracao, (atributo, mensagem)|
        it "com #{alteracao.inspect}, não cadastra e mostra \"#{mensagem}\" no campo" do
          expect { post controle_funcionarios_path, params: { cadastro_funcionario: dados_validos(**alteracao) } }
            .not_to change(Funcionario, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(erro_do_campo(atributo)).to eq(mensagem)
        end
      end

      it "mantém o perfil escolhido quando o formulário volta com erro" do
        post controle_funcionarios_path, params: { cadastro_funcionario: dados_validos(nome: "", administrador: "true") }

        expect(html.at("input#cadastro_funcionario_administrador_true")["checked"]).to be_present
      end
    end
  end
end
