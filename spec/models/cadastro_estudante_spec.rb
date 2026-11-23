require "rails_helper"

RSpec.describe CadastroEstudante, type: :model do
  subject(:cadastro) { described_class.new(dados_validos_de_cadastro) }

  describe "#save com dados válidos" do
    it "retorna true" do
      expect(cadastro.save).to be(true)
    end

    it "cria o usuário e o estudante" do
      expect { cadastro.save }
        .to change(Usuario, :count).by(1)
        .and change(Estudante, :count).by(1)
    end

    it "liga o estudante ao usuário com os dados informados" do
      cadastro.save
      estudante = Estudante.find_by!(matricula: "231012345")

      expect(estudante.nome).to eq("Maria Souza")
      expect(estudante.email).to eq("maria@aluno.unb.br")
      expect(estudante.saldo).to eq(0)
      expect(estudante.usuario.authenticate_senha("senha123")).to be_truthy
    end
  end

  shared_examples "cadastro recusado" do |campo, mensagem|
    it "retorna false" do
      expect(cadastro.save).to be(false)
    end

    it "não cria usuário nem estudante" do
      expect { cadastro.save }
        .to not_change(Usuario, :count)
        .and not_change(Estudante, :count)
    end

    it "informa \"#{mensagem}\" no campo #{campo}" do
      cadastro.save

      expect(cadastro.errors[campo]).to include(mensagem)
    end
  end

  describe "#save com matrícula inválida" do
    {
      "23101234" => "A matrícula deve conter 9 dígitos",
      "2310123456" => "A matrícula deve conter 9 dígitos",
      "23A012345" => "A matrícula deve conter apenas números",
      "" => "A matrícula é obrigatória"
    }.each do |matricula, mensagem|
      context "quando a matrícula é #{matricula.inspect}" do
        subject(:cadastro) { described_class.new(dados_validos_de_cadastro(matricula:)) }

        include_examples "cadastro recusado", :matricula, mensagem
      end
    end
  end

  describe "#save com matrícula já cadastrada" do
    before { criar_estudante(matricula: "231012345") }

    include_examples "cadastro recusado", :matricula, "Esta matrícula já está cadastrada"
  end

  describe "#save com e-mail já cadastrado" do
    before { criar_estudante(matricula: "200000000", email: "maria@aluno.unb.br") }

    include_examples "cadastro recusado", :email, "Este e-mail já está cadastrado"
  end

  describe "#save com senha e confirmação diferentes" do
    subject(:cadastro) { described_class.new(dados_validos_de_cadastro(confirmacao_senha: "outra456")) }

    include_examples "cadastro recusado", :confirmacao_senha, "A confirmação de senha não confere"
  end

  describe "#save com senha curta" do
    subject(:cadastro) { described_class.new(dados_validos_de_cadastro(senha: "12345", confirmacao_senha: "12345")) }

    include_examples "cadastro recusado", :senha, "A senha deve ter no mínimo 6 caracteres"
  end

  describe "#save sem nome" do
    subject(:cadastro) { described_class.new(dados_validos_de_cadastro(nome: "")) }

    include_examples "cadastro recusado", :nome, "O nome é obrigatório"
  end

  describe "#save sem e-mail" do
    subject(:cadastro) { described_class.new(dados_validos_de_cadastro(email: "")) }

    include_examples "cadastro recusado", :email, "O e-mail é obrigatório"
  end

  it "reúne os erros de usuário e estudante de uma só vez" do
    cadastro = described_class.new(dados_validos_de_cadastro(nome: "", matricula: "23A012345", confirmacao_senha: "x"))

    expect(cadastro).not_to be_valid
    expect(cadastro.errors.attribute_names).to contain_exactly(:nome, :matricula, :confirmacao_senha)
  end

  # Outra requisição grava a mesma matrícula depois da validação do formulário
  # e antes do INSERT: o cadastro deve ser desfeito por inteiro.
  describe "#save com cadastro concorrente da mesma matrícula" do
    before do
      criar_estudante(matricula: "231012345")

      validacoes = 0
      allow(cadastro).to receive(:valid?).and_wrap_original do |original, *args|
        (validacoes += 1) == 1 ? true : original.call(*args)
      end
    end

    context "quando o conflito é detectado pela validação do modelo" do
      include_examples "cadastro recusado", :matricula, "Esta matrícula já está cadastrada"
    end

    context "quando o conflito é detectado pelo índice único do banco" do
      before do
        allow_any_instance_of(Estudante).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
      end

      include_examples "cadastro recusado", :matricula, "Esta matrícula já está cadastrada"
    end
  end
end
