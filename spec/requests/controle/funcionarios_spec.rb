require "rails_helper"

RSpec.describe "Gestão de funcionários", type: :request do
  let!(:administrador) { criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true) }

  def html
    Nokogiri::HTML5(response.body)
  end

  # Nome, SIAPE, e-mail e perfil de cada linha da lista.
  def linhas_da_lista
    html.css("#funcionarios tbody tr").map { |linha| linha.css("td").first(4).map { |celula| celula.text.squish } }
  end

  def acoes_da_linha(siape)
    linha = html.css("#funcionarios tbody tr").find { |tr| tr.css("td")[1].text.strip == siape }
    linha.css(".tabela__acoes a, .tabela__acoes button").map { |acao| acao.text.squish }
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

    it "não deixa funcionário que não é administrador ver, cadastrar, editar nem remover" do
      entrar_como_funcionario(criar_funcionario(siape: "1234567"))

      get controle_funcionarios_path
      expect(response).to redirect_to(controle_path)
      expect(flash[:alert]).to eq("Acesso permitido apenas para administradores")

      expect { post controle_funcionarios_path, params: { cadastro_funcionario: dados_validos(administrador: "true") } }
        .not_to change(Funcionario, :count)
      expect(response).to redirect_to(controle_path)

      patch controle_funcionario_path(administrador), params: { cadastro_funcionario: { administrador: "false" } }
      expect(administrador.reload).to be_administrador

      expect { delete controle_funcionario_path(administrador) }.not_to change(Funcionario, :count)
      expect(response).to redirect_to(controle_path)
    end
  end

  context "como administrador" do
    before { entrar_como_funcionario(administrador) }

    describe "lista" do
      it "mostra os funcionários em ordem de nome, com SIAPE, e-mail e perfil, e marca o próprio administrador" do
        usuario = Usuario.create!(nome: "Bruno Alves", email: "bruno@unb.br", senha: "senha123")
        Funcionario.create!(usuario:, siape: "2223334")

        get controle_funcionarios_path

        expect(response).to have_http_status(:ok)
        expect(linhas_da_lista).to eq([
          [ "Bruno Alves", "2223334", "bruno@unb.br", "Funcionário" ],
          [ "Funcionário Existente Você", "7654321", "admin@unb.br", "Administrador" ]
        ])
      end

      it "deixa editar todos, mas não mostra Remover na linha do próprio administrador" do
        criar_funcionario(siape: "1234567", email: "jose@unb.br")

        get controle_funcionarios_path

        expect(acoes_da_linha("1234567")).to eq([ "Editar", "Remover" ])
        expect(acoes_da_linha("7654321")).to eq([ "Editar" ])
      end

      it "marca a aba Funcionários como ativa" do
        get controle_funcionarios_path

        expect(html.css(".abas__item--ativa").map(&:text)).to eq([ "Funcionários" ])
      end
    end

    describe "formulário de cadastro" do
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
        { senha: "", confirmacao_senha: "" } => [ :senha, "A senha é obrigatória" ],
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

    describe "edição" do
      let!(:jose) { criar_funcionario(siape: "1234567", email: "jose@unb.br") }

      def editar(funcionario, **dados)
        patch controle_funcionario_path(funcionario),
              params: { cadastro_funcionario: { senha: "", confirmacao_senha: "" }.merge(dados) }
      end

      it "mostra o formulário preenchido, com a senha em branco" do
        get edit_controle_funcionario_path(jose)

        expect(response).to have_http_status(:ok)
        expect(html.at("input#cadastro_funcionario_nome")["value"]).to eq("Funcionário Existente")
        expect(html.at("input#cadastro_funcionario_siape")["value"]).to eq("1234567")
        expect(html.at("input#cadastro_funcionario_email")["value"]).to eq("jose@unb.br")
        expect(html.at("input#cadastro_funcionario_senha")["value"]).to be_nil
        expect(html.at("input#cadastro_funcionario_administrador_false")["checked"]).to be_present
        expect(html.at("label[for=cadastro_funcionario_senha]").text).to eq("Nova senha")
      end

      it "salva nome, SIAPE, e-mail e perfil, mantém a senha e volta para a lista" do
        editar(jose, nome: "José Pereira", siape: "1234568", email: "jose.pereira@unb.br", administrador: "true")

        expect(response).to redirect_to(controle_funcionarios_path)
        expect(flash[:notice]).to eq("Funcionário atualizado com sucesso")
        expect(jose.reload).to have_attributes(nome: "José Pereira", siape: "1234568",
                                               email: "jose.pereira@unb.br", administrador: true)
        expect(Funcionario.autenticar(siape: "1234568", senha: "senha123")).to eq(jose)
      end

      it "troca a senha quando uma nova é informada" do
        editar(jose, senha: "nova1234", confirmacao_senha: "nova1234")

        expect(response).to redirect_to(controle_funcionarios_path)
        expect(Funcionario.autenticar(siape: "1234567", senha: "nova1234")).to eq(jose)
        expect(Funcionario.autenticar(siape: "1234567", senha: "senha123")).to be_nil
      end

      it "mantém a senha se o campo nem vier no formulário" do
        patch controle_funcionario_path(jose), params: { cadastro_funcionario: { nome: "José Pereira" } }

        expect(response).to redirect_to(controle_funcionarios_path)
        expect(Funcionario.autenticar(siape: "1234567", senha: "senha123")).to eq(jose)
      end

      it "aceita salvar sem mudar nada: o SIAPE e o e-mail do próprio funcionário não contam como repetidos" do
        editar(jose, nome: "Funcionário Existente", siape: "1234567", email: "jose@unb.br")

        expect(response).to redirect_to(controle_funcionarios_path)
      end

      {
        { siape: "7654321" } => [ :siape, "Este SIAPE já está cadastrado" ],
        { siape: "12A4567" } => [ :siape, "O SIAPE deve conter apenas números" ],
        { email: "admin@unb.br" } => [ :email, "Este e-mail já está cadastrado" ],
        { nome: "" } => [ :nome, "O nome é obrigatório" ],
        { senha: "12345", confirmacao_senha: "12345" } => [ :senha, "A senha deve ter no mínimo 6 caracteres" ],
        { senha: "nova1234", confirmacao_senha: "outra456" } => [ :confirmacao_senha, "A confirmação de senha não confere" ],
        { senha: "", confirmacao_senha: "nova1234" } => [ :confirmacao_senha, "A confirmação de senha não confere" ]
      }.each do |alteracao, (atributo, mensagem)|
        it "com #{alteracao.inspect}, não salva nada e mostra \"#{mensagem}\" no campo" do
          editar(jose, administrador: "true", **alteracao)

          expect(response).to have_http_status(:unprocessable_content)
          expect(erro_do_campo(atributo)).to eq(mensagem)
          expect(jose.reload).to have_attributes(nome: "Funcionário Existente", siape: "1234567",
                                                 email: "jose@unb.br", administrador: false)
          expect(Funcionario.autenticar(siape: "1234567", senha: "senha123")).to eq(jose)
        end
      end

      it "tira o acesso de administrador de outro administrador" do
        outro = criar_funcionario(siape: "2223334", email: "outro@unb.br", administrador: true)

        editar(outro, administrador: "false")

        expect(response).to redirect_to(controle_funcionarios_path)
        expect(outro.reload).not_to be_administrador
      end

      it "deixa o administrador alterar os próprios dados" do
        editar(administrador, nome: "Ana Lima", administrador: "true")

        expect(response).to redirect_to(controle_funcionarios_path)
        expect(administrador.reload.nome).to eq("Ana Lima")
      end

      it "não deixa o administrador tirar o próprio acesso de administrador" do
        editar(administrador, administrador: "false")

        expect(response).to have_http_status(:unprocessable_content)
        expect(erro_do_campo(:administrador)).to eq("Você não pode tirar o seu próprio acesso de administrador")
        expect(administrador.reload).to be_administrador
      end

      it "responde 404 para funcionário inexistente" do
        get edit_controle_funcionario_path(id: 0)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "remoção" do
      let!(:jose) { criar_funcionario(siape: "1234567", email: "jose@unb.br") }

      it "remove o funcionário e a conta de usuário dele, e volta para a lista com a mensagem de sucesso" do
        expect { delete controle_funcionario_path(jose) }
          .to change(Funcionario, :count).by(-1)
          .and change(Usuario, :count).by(-1)

        expect(response).to redirect_to(controle_funcionarios_path)
        expect(response).to have_http_status(:see_other)
        expect(flash[:notice]).to eq("Funcionário removido com sucesso")
        expect(Funcionario.autenticar(siape: "1234567", senha: "senha123")).to be_nil
      end

      it "encerra as sessões do funcionário e libera a catraca que ele operava" do
        catraca = catraca_padrao
        PontoAcesso.abrir!(funcionario: jose, catraca:)
        jose.usuario.sessoes.create!

        delete controle_funcionario_path(jose)

        expect(Sessao.where(usuario_id: jose.usuario_id)).to be_empty
        expect(catraca.reload).not_to be_em_uso
      end

      it "não deixa o administrador remover a própria conta" do
        expect { delete controle_funcionario_path(administrador) }.not_to change(Funcionario, :count)

        expect(response).to redirect_to(controle_funcionarios_path)
        expect(flash[:alert]).to eq("Você não pode remover a sua própria conta")
      end

      it "responde 404 para funcionário inexistente" do
        delete controle_funcionario_path(id: 0)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
