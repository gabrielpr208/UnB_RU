require "rails_helper"

RSpec.describe "Gestão de restaurantes", type: :request do
  let!(:administrador) { criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true) }
  let!(:darcy) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
  let!(:gama) { Restaurante.create!(nome: "RU Gama", campus: "Gama") }

  def html
    Nokogiri::HTML5(response.body)
  end

  def nomes_na_lista
    html.css("#restaurantes tbody tr td:first-child").map { |celula| celula.text.strip }
  end

  def erro_do_campo(atributo)
    html.at("#restaurante_#{atributo}_mensagem.campo__erro")&.text&.strip
  end

  describe "acesso" do
    it "pede login a quem não está logado" do
      get controle_restaurantes_path

      expect(response).to redirect_to(login_controle_path)
      expect(flash[:alert]).to eq("Você deve estar logado para acessar esta página")
    end

    it "não deixa estudante entrar" do
      entrar_como(criar_estudante)
      get controle_restaurantes_path

      expect(response).to redirect_to(login_controle_path)
      expect(flash[:alert]).to eq("Acesso por estudantes não autorizado")
    end

    it "manda o funcionário que não é administrador de volta para o início, sem alterar nada" do
      entrar_como_funcionario(criar_funcionario(siape: "1234567"))

      get controle_restaurantes_path
      expect(response).to redirect_to(controle_path)
      expect(flash[:alert]).to eq("Acesso permitido apenas para administradores")

      expect { delete controle_restaurante_path(gama) }.not_to change(Restaurante, :count)
      expect { post controle_restaurantes_path, params: { restaurante: { nome: "FUP", campus: "Planaltina" } } }
        .not_to change(Restaurante, :count)
    end

    it "só mostra a aba Restaurantes para o administrador" do
      entrar_como_funcionario(criar_funcionario(siape: "1234567"))
      get controle_path
      expect(html.css(".abas__item").map(&:text)).to eq([ "Início" ])

      delete logout_controle_path
      entrar_como_funcionario(administrador)
      get controle_path
      expect(html.css(".abas__item").map(&:text)).to eq([ "Início", "Restaurantes" ])
    end
  end

  context "como administrador" do
    before { entrar_como_funcionario(administrador) }

    describe "lista" do
      it "mostra os restaurantes em ordem alfabética, com o campus" do
        Restaurante.create!(nome: "FUP", campus: "Planaltina")

        get controle_restaurantes_path

        expect(response).to have_http_status(:ok)
        expect(nomes_na_lista).to eq([ "FUP", "RU Darcy Ribeiro", "RU Gama" ])
        expect(html.at("#restaurantes tbody tr td:nth-child(2)").text).to eq("Planaltina")
      end

      it "marca a aba Restaurantes, e não a Início, como ativa" do
        get controle_restaurantes_path

        expect(html.css(".abas__item--ativa").map(&:text)).to eq([ "Restaurantes" ])
      end

      it "avisa quando não há restaurantes" do
        Restaurante.delete_all

        get controle_restaurantes_path

        expect(response.body).to include("Nenhum restaurante cadastrado")
      end
    end

    describe "cadastro" do
      it "mostra o formulário" do
        get new_controle_restaurante_path

        expect(response).to have_http_status(:ok)
        expect(html.at("input#restaurante_nome")).to be_present
        expect(html.css("datalist#campi option").map { |opcao| opcao["value"] }).to eq(Restaurante::CAMPI)
      end

      it "cadastra e volta para a lista com a mensagem de sucesso" do
        expect do
          post controle_restaurantes_path, params: { restaurante: { nome: "RU FCE", campus: "Ceilândia" } }
        end.to change(Restaurante, :count).by(1)

        expect(response).to redirect_to(controle_restaurantes_path)
        expect(flash[:notice]).to eq("Restaurante cadastrado com sucesso")
        expect(Restaurante.last).to have_attributes(nome: "RU FCE", campus: "Ceilândia")
      end

      {
        { nome: "", campus: "Ceilândia" } => [ :nome, "O nome é obrigatório" ],
        { nome: "RU", campus: "Ceilândia" } => [ :nome, "O nome deve ter entre 3 e 50 caracteres" ],
        { nome: "RU FCE", campus: "" } => [ :campus, "O campus é obrigatório" ],
        { nome: "RU Taguatinga", campus: "Taguatinga" } => [ :campus, "Campus inválido" ],
        { nome: "RU Gama", campus: "Gama" } => [ :nome, "Já existe um restaurante com este nome" ]
      }.each do |dados, (atributo, mensagem)|
        it "com #{dados.inspect}, não cadastra e mostra \"#{mensagem}\" no campo" do
          expect { post controle_restaurantes_path, params: { restaurante: dados } }.not_to change(Restaurante, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(erro_do_campo(atributo)).to eq(mensagem)
        end
      end
    end

    describe "edição" do
      it "mostra o formulário preenchido" do
        get edit_controle_restaurante_path(darcy)

        expect(html.at("input#restaurante_nome")["value"]).to eq("RU Darcy Ribeiro")
        expect(html.at("input#restaurante_campus")["value"]).to eq("Darcy Ribeiro")
      end

      it "salva e volta para a lista com a mensagem de sucesso" do
        patch controle_restaurante_path(darcy), params: { restaurante: { nome: "RU Central" } }

        expect(response).to redirect_to(controle_restaurantes_path)
        expect(flash[:notice]).to eq("Restaurante atualizado com sucesso")
        expect(darcy.reload.nome).to eq("RU Central")
      end

      it "não salva nome repetido e mantém o nome antigo" do
        patch controle_restaurante_path(gama), params: { restaurante: { nome: "RU Darcy Ribeiro" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(erro_do_campo(:nome)).to eq("Já existe um restaurante com este nome")
        expect(gama.reload.nome).to eq("RU Gama")
      end

      it "aceita salvar o próprio nome sem acusar repetição" do
        patch controle_restaurante_path(gama), params: { restaurante: { nome: "RU Gama", campus: "Gama" } }

        expect(response).to redirect_to(controle_restaurantes_path)
      end
    end

    describe "remoção" do
      it "remove restaurante sem catracas" do
        expect { delete controle_restaurante_path(gama) }.to change(Restaurante, :count).by(-1)

        expect(response).to redirect_to(controle_restaurantes_path)
        expect(response).to have_http_status(:see_other)
        expect(flash[:notice]).to eq("Restaurante removido com sucesso")
      end

      it "não remove restaurante com catracas e explica o motivo" do
        darcy.catracas.create!(identificador: "01")

        expect { delete controle_restaurante_path(darcy) }.not_to change(Restaurante, :count)

        expect(response).to redirect_to(controle_restaurantes_path)
        expect(flash[:alert]).to eq("Não é possível remover um restaurante com catracas cadastradas")
      end

      it "responde 404 para restaurante inexistente" do
        delete controle_restaurante_path(id: 0)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
