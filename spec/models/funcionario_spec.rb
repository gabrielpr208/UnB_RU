require "rails_helper"

RSpec.describe Funcionario, type: :model do
  let(:usuario) { Usuario.new(nome: "José Pereira", email: "jose@unb.br", senha: "senha123") }

  subject(:funcionario) { described_class.new(usuario:, siape: "1234567") }

  it "é válido com usuário e SIAPE de 7 dígitos" do
    expect(funcionario).to be_valid
  end

  it "usa o id do usuário como chave primária" do
    funcionario.save!

    expect(funcionario.id).to eq(usuario.id)
    expect(described_class.find(usuario.id)).to eq(funcionario)
    expect(usuario.reload.funcionario).to eq(funcionario)
  end

  it "expõe o nome, o primeiro nome e o e-mail do usuário" do
    expect(funcionario.nome).to eq("José Pereira")
    expect(funcionario.primeiro_nome).to eq("José")
    expect(funcionario.email).to eq("jose@unb.br")
  end

  it "não é administrador por padrão" do
    funcionario.save!

    expect(funcionario.reload).not_to be_administrador
  end

  describe "SIAPE" do
    {
      "123456" => "O SIAPE deve conter 7 dígitos",
      "12345678" => "O SIAPE deve conter 7 dígitos",
      "123A567" => "O SIAPE deve conter apenas números",
      "123-4567" => "O SIAPE deve conter apenas números",
      "" => "O SIAPE é obrigatório",
      "   " => "O SIAPE é obrigatório"
    }.each do |siape, mensagem|
      it "#{siape.inspect} é recusado com a mensagem \"#{mensagem}\"" do
        funcionario.siape = siape

        expect(funcionario).not_to be_valid
        expect(funcionario.errors[:siape]).to eq([ mensagem ])
      end
    end

    it "ignora espaços nas pontas" do
      funcionario.siape = " 1234567 "

      expect(funcionario.siape).to eq("1234567")
      expect(funcionario).to be_valid
    end

    it "não pode repetir" do
      criar_funcionario(siape: "1234567")

      expect(funcionario).not_to be_valid
      expect(funcionario.errors[:siape]).to eq([ "Este SIAPE já está cadastrado" ])
    end

    it "é único também no banco de dados" do
      criar_funcionario(siape: "1234567")
      usuario.save!

      expect { funcionario.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe ".autenticar" do
    let!(:existente) { criar_funcionario(siape: "1234567") }

    it "devolve o funcionário quando SIAPE e senha conferem" do
      expect(described_class.autenticar(siape: "1234567", senha: "senha123")).to eq(existente)
    end

    it "ignora espaços nas pontas do SIAPE" do
      expect(described_class.autenticar(siape: " 1234567 ", senha: "senha123")).to eq(existente)
    end

    {
      "senha errada" => [ "1234567", "senha321" ],
      "SIAPE inexistente" => [ "7654321", "senha123" ],
      "SIAPE com 6 dígitos" => [ "123456", "senha123" ],
      "SIAPE com 8 dígitos" => [ "12345678", "senha123" ],
      "SIAPE com letras" => [ "123A567", "senha123" ],
      "SIAPE em branco" => [ "", "senha123" ],
      "SIAPE nulo" => [ nil, "senha123" ],
      "senha em branco" => [ "1234567", "" ],
      "senha nula" => [ "1234567", nil ]
    }.each do |caso, (siape, senha)|
      it "devolve nil com #{caso}" do
        expect(described_class.autenticar(siape:, senha:)).to be_nil
      end
    end

    it "não aceita a matrícula e a senha de um estudante" do
      criar_estudante(matricula: "231012345")

      expect(described_class.autenticar(siape: "231012345", senha: "senha123")).to be_nil
    end

    it "calcula um hash de senha mesmo quando o SIAPE não existe" do
      expect(BCrypt::Password).to receive(:create).once.and_call_original

      described_class.autenticar(siape: "7654321", senha: "senha123")
    end
  end

  describe "ponto de acesso" do
    let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
    let(:catraca) { restaurante.catracas.create!(identificador: "01") }

    before { funcionario.save! }

    it "não tem ponto de acesso atual antes de escolher uma catraca" do
      expect(funcionario.ponto_acesso_atual).to be_nil
    end

    it "tem como atual o ponto de acesso em aberto" do
      ponto = PontoAcesso.abrir!(funcionario:, catraca:)

      expect(funcionario.reload.ponto_acesso_atual).to eq(ponto)
    end

    it "encerra o ponto de acesso atual" do
      ponto = PontoAcesso.abrir!(funcionario:, catraca:)

      funcionario.encerrar_ponto_acesso

      expect(ponto.reload.encerrado_em).to be_present
      expect(funcionario.reload.ponto_acesso_atual).to be_nil
    end
  end

  it "é removido junto com o usuário" do
    funcionario.save!

    expect { usuario.destroy }.to change(described_class, :count).by(-1)
  end

  describe ".em_ordem" do
    it "ordena pelo nome do usuário" do
      criar_funcionario(siape: "1111111", email: "z@unb.br").usuario.update!(nome: "Zélia Rocha")
      criar_funcionario(siape: "2222222", email: "a@unb.br").usuario.update!(nome: "Ana Lima")

      expect(described_class.em_ordem.map(&:nome)).to eq([ "Ana Lima", "Zélia Rocha" ])
    end
  end

  describe "#remover" do
    let!(:administrador) { criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true) }

    before { funcionario.save! }

    it "remove o funcionário, o usuário e as sessões dele" do
      usuario.sessoes.create!

      expect { expect(funcionario.remover(responsavel: administrador)).to be_truthy }
        .to change(described_class, :count).by(-1)
        .and change(Usuario, :count).by(-1)
        .and change(Sessao, :count).by(-1)
    end

    it "libera a catraca em que o funcionário estava operando" do
      catraca = catraca_padrao
      PontoAcesso.abrir!(funcionario:, catraca:)

      funcionario.remover(responsavel: administrador)

      expect(catraca.reload).not_to be_em_uso
    end

    it "não remove a própria conta de quem está removendo" do
      expect { expect(administrador.remover(responsavel: administrador)).to be(false) }
        .not_to change(described_class, :count)

      expect(administrador.errors[:base]).to eq([ "Você não pode remover a sua própria conta" ])
    end
  end
end
