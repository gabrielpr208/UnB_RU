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

  describe ".editar" do
    let!(:administrador) { criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true) }
    let!(:jose) { criar_funcionario(siape: "1234567", email: "jose@unb.br") }

    def edicao(funcionario, **alteracoes)
      described_class.editar(funcionario, responsavel: administrador).tap { |cadastro| cadastro.assign_attributes(alteracoes) }
    end

    it "começa com os dados atuais do funcionário e a senha em branco" do
      expect(described_class.editar(jose, responsavel: administrador)).to have_attributes(
        nome: "Funcionário Existente", siape: "1234567", email: "jose@unb.br", administrador: false,
        senha: nil, confirmacao_senha: nil
      )
    end

    it "altera o usuário e o funcionário sem criar registros novos" do
      cadastro = edicao(jose, nome: "José Pereira", siape: "1234568", email: "jose.p@unb.br", administrador: true)

      expect { expect(cadastro.save).to be(true) }
        .to not_change(Usuario, :count)
        .and not_change(Funcionario, :count)

      expect(jose.reload).to have_attributes(nome: "José Pereira", siape: "1234568", email: "jose.p@unb.br",
                                             administrador: true)
    end

    it "mantém a senha quando a nova senha fica em branco" do
      edicao(jose, nome: "José Pereira", senha: "", confirmacao_senha: "").save

      expect(Funcionario.autenticar(siape: "1234567", senha: "senha123")).to eq(jose)
    end

    it "troca a senha quando uma nova é informada" do
      edicao(jose, senha: "nova1234", confirmacao_senha: "nova1234").save

      expect(Funcionario.autenticar(siape: "1234567", senha: "nova1234")).to eq(jose)
    end

    {
      { senha: "", confirmacao_senha: "nova1234" } => [ :confirmacao_senha, "A confirmação de senha não confere" ],
      { senha: "nova1234", confirmacao_senha: "" } => [ :confirmacao_senha, "A confirmação de senha não confere" ],
      { senha: "12345", confirmacao_senha: "12345" } => [ :senha, "A senha deve ter no mínimo 6 caracteres" ]
    }.each do |alteracoes, (campo, mensagem)|
      it "com #{alteracoes}, informa \"#{mensagem}\" e mantém a senha atual" do
        cadastro = edicao(jose, **alteracoes)

        expect(cadastro.save).to be(false)
        expect(cadastro.errors[campo]).to eq([ mensagem ])
        expect(Funcionario.autenticar(siape: "1234567", senha: "senha123")).to eq(jose)
      end
    end

    it "não altera o registro recebido quando a gravação falha" do
      cadastro = edicao(jose, nome: "", siape: "7654321")

      expect(cadastro.save).to be(false)
      expect(cadastro.errors[:siape]).to eq([ "Este SIAPE já está cadastrado" ])
      expect(jose).to have_attributes(nome: "Funcionário Existente", siape: "1234567")
    end

    it "deixa tirar o acesso de administrador de outro administrador" do
      outro = criar_funcionario(siape: "2223334", email: "outro@unb.br", administrador: true)

      expect(edicao(outro, administrador: false).save).to be(true)
      expect(outro.reload).not_to be_administrador
    end

    it "não deixa quem está editando tirar o próprio acesso de administrador" do
      cadastro = edicao(administrador, administrador: false)

      expect(cadastro.save).to be(false)
      expect(cadastro.errors[:administrador]).to eq([ "Você não pode tirar o seu próprio acesso de administrador" ])
      expect(administrador.reload).to be_administrador
    end

    # Outra requisição grava o mesmo SIAPE depois da validação do formulário e antes do UPDATE.
    it "mostra o SIAPE repetido quando o conflito só aparece no banco" do
      cadastro = edicao(jose, siape: "7654321")
      allow_any_instance_of(Funcionario).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)
      validacoes = 0
      allow(cadastro).to receive(:valid?).and_wrap_original do |original, *args|
        (validacoes += 1) == 1 ? true : original.call(*args)
      end

      expect(cadastro.save).to be(false)
      expect(cadastro.errors[:siape]).to eq([ "Este SIAPE já está cadastrado" ])
      expect(jose.reload.siape).to eq("1234567")
    end
  end
end
