require "rails_helper"

RSpec.describe Estudante, type: :model do
  let(:usuario) { Usuario.new(nome: "Maria Souza", email: "maria@aluno.unb.br", senha: "senha123") }

  subject(:estudante) { described_class.new(usuario:, matricula: "231012345") }

  it "é válido com usuário e matrícula de 9 dígitos" do
    expect(estudante).to be_valid
  end

  it "usa o id do usuário como chave primária" do
    estudante.save!

    expect(estudante.id).to eq(usuario.id)
    expect(described_class.find(usuario.id)).to eq(estudante)
    expect(usuario.reload.estudante).to eq(estudante)
  end

  it "expõe o nome e o e-mail do usuário" do
    expect(estudante.nome).to eq("Maria Souza")
    expect(estudante.email).to eq("maria@aluno.unb.br")
  end

  describe "matrícula" do
    {
      "23101234" => "A matrícula deve conter 9 dígitos",
      "2310123456" => "A matrícula deve conter 9 dígitos",
      "23A012345" => "A matrícula deve conter apenas números",
      "23/1012345" => "A matrícula deve conter apenas números",
      "23A" => "A matrícula deve conter apenas números",
      "" => "A matrícula é obrigatória",
      "   " => "A matrícula é obrigatória"
    }.each do |matricula, mensagem|
      it "#{matricula.inspect} é recusada com a mensagem \"#{mensagem}\"" do
        estudante.matricula = matricula

        expect(estudante).not_to be_valid
        expect(estudante.errors[:matricula]).to eq([ mensagem ])
      end
    end

    it "ignora espaços nas pontas" do
      estudante.matricula = " 231012345 "

      expect(estudante.matricula).to eq("231012345")
      expect(estudante).to be_valid
    end

    it "não pode repetir" do
      criar_estudante(matricula: "231012345")

      expect(estudante).not_to be_valid
      expect(estudante.errors[:matricula]).to eq([ "Esta matrícula já está cadastrada" ])
    end

    it "é única também no banco de dados" do
      criar_estudante(matricula: "231012345")
      usuario.save!

      expect { estudante.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "saldo" do
    it "começa em zero" do
      estudante.save!

      expect(estudante.reload.saldo).to eq(0)
    end

    it "não pode ser negativo" do
      estudante.saldo = -0.01

      expect(estudante).not_to be_valid
      expect(estudante.errors[:saldo]).to be_present
    end

    it "não pode ser negativo também no banco de dados" do
      estudante.save!

      expect { estudante.update_column(:saldo, -1) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  it "é removido junto com o usuário" do
    estudante.save!

    expect { usuario.destroy }.to change(described_class, :count).by(-1)
  end
end
