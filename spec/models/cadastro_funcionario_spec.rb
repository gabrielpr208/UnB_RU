require "rails_helper"

RSpec.describe CadastroFuncionario, type: :model do
  def dados_validos(**alteracoes)
    {
      nome: "Ana Lima",
      siape: "7654321",
      email: "ana@unb.br",
      senha: "senha123",
      confirmacao_senha: "senha123"
    }.merge(alteracoes)
  end

  subject(:cadastro) { described_class.new(dados_validos) }

  describe "#save com dados válidos" do
    it "cria o usuário e o funcionário" do
      expect(cadastro.save).to be(true)
      expect(Funcionario.count).to eq(1)
      expect(Usuario.count).to eq(1)
    end

    it "liga o funcionário ao usuário com os dados informados, e ele consegue entrar com SIAPE e senha" do
      cadastro.save
      funcionario = Funcionario.find_by!(siape: "7654321")

      expect(funcionario).to have_attributes(nome: "Ana Lima", email: "ana@unb.br")
      expect(Funcionario.autenticar(siape: "7654321", senha: "senha123")).to eq(funcionario)
    end
  end

  describe "perfil" do
    it "não é administrador quando nada é escolhido" do
      cadastro.save

      expect(Funcionario.sole).not_to be_administrador
    end

    {
      "true" => true, "1" => true, true => true,
      "false" => false, "0" => false, false => false, "" => false
    }.each do |valor, administrador|
      it "com administrador #{valor.inspect}, #{administrador ? "é" : "não é"} administrador" do
        described_class.new(dados_validos(administrador: valor)).save

        expect(Funcionario.sole.administrador?).to be(administrador)
      end
    end
  end

  shared_examples "cadastro recusado" do |campo, mensagem|
    it "não cria usuário nem funcionário e informa \"#{mensagem}\" no campo #{campo}" do
      expect { expect(cadastro.save).to be(false) }
        .to not_change(Usuario, :count)
        .and not_change(Funcionario, :count)

      expect(cadastro.errors[campo]).to include(mensagem)
    end
  end

  describe "#save com SIAPE inválido" do
    {
      "123456" => "O SIAPE deve conter 7 dígitos",
      "12345678" => "O SIAPE deve conter 7 dígitos",
      "123A567" => "O SIAPE deve conter apenas números",
      "" => "O SIAPE é obrigatório"
    }.each do |siape, mensagem|
      context "quando o SIAPE é #{siape.inspect}" do
        subject(:cadastro) { described_class.new(dados_validos(siape:)) }

        include_examples "cadastro recusado", :siape, mensagem
      end
    end
  end

  describe "#save com SIAPE já cadastrado" do
    before { criar_funcionario(siape: "7654321") }

    include_examples "cadastro recusado", :siape, "Este SIAPE já está cadastrado"
  end

  describe "#save com e-mail já cadastrado" do
    before { criar_funcionario(siape: "1234567", email: "ana@unb.br") }

    include_examples "cadastro recusado", :email, "Este e-mail já está cadastrado"
  end

  describe "#save com senha e confirmação diferentes" do
    subject(:cadastro) { described_class.new(dados_validos(confirmacao_senha: "outra456")) }

    include_examples "cadastro recusado", :confirmacao_senha, "A confirmação de senha não confere"
  end

  describe "#save com senha curta" do
    subject(:cadastro) { described_class.new(dados_validos(senha: "12345", confirmacao_senha: "12345")) }

    include_examples "cadastro recusado", :senha, "A senha deve ter no mínimo 6 caracteres"
  end

  describe "#save sem nome" do
    subject(:cadastro) { described_class.new(dados_validos(nome: "")) }

    include_examples "cadastro recusado", :nome, "O nome é obrigatório"
  end

  describe "#save sem e-mail" do
    subject(:cadastro) { described_class.new(dados_validos(email: "")) }

    include_examples "cadastro recusado", :email, "O e-mail é obrigatório"
  end

  # Outra requisição grava o mesmo SIAPE depois da validação do formulário e antes do INSERT.
  describe "#save com cadastro concorrente do mesmo SIAPE" do
    before do
      criar_funcionario(siape: "7654321")
      allow_any_instance_of(Funcionario).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)

      validacoes = 0
      allow(cadastro).to receive(:valid?).and_wrap_original do |original, *args|
        (validacoes += 1) == 1 ? true : original.call(*args)
      end
    end

    include_examples "cadastro recusado", :siape, "Este SIAPE já está cadastrado"
  end
end
