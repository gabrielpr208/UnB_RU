require "rails_helper"

RSpec.describe Usuario, type: :model do
  subject(:usuario) do
    described_class.new(nome: "Maria Souza", email: "maria@aluno.unb.br",
                        senha: "senha123", senha_confirmation: "senha123")
  end

  it "é válido com nome, e-mail e senha" do
    expect(usuario).to be_valid
  end

  describe "nome" do
    it "é obrigatório" do
      usuario.nome = "   "

      expect(usuario).not_to be_valid
      expect(usuario.errors[:nome]).to eq([ "O nome é obrigatório" ])
    end

    it "remove espaços extras" do
      usuario.nome = "  Maria   Souza "

      expect(usuario.nome).to eq("Maria Souza")
    end
  end

  describe "e-mail" do
    it "é obrigatório" do
      usuario.email = ""

      expect(usuario).not_to be_valid
      expect(usuario.errors[:email]).to eq([ "O e-mail é obrigatório" ])
    end

    it "precisa ter um formato válido" do
      usuario.email = "maria@"

      expect(usuario).not_to be_valid
      expect(usuario.errors[:email]).to eq([ "Informe um e-mail válido" ])
    end

    it "é gravado sem espaços e em minúsculas" do
      usuario.email = "  Maria@Aluno.UnB.br "

      expect(usuario.email).to eq("maria@aluno.unb.br")
    end

    it "não pode repetir, mesmo com maiúsculas diferentes" do
      usuario.save!
      outro = described_class.new(nome: "Outra Maria", email: "MARIA@aluno.unb.br", senha: "senha123")

      expect(outro).not_to be_valid
      expect(outro.errors[:email]).to eq([ "Este e-mail já está cadastrado" ])
    end

    it "é único também no banco de dados" do
      usuario.save!
      outro = described_class.new(nome: "Outra Maria", email: "maria@aluno.unb.br", senha: "senha123")

      expect { outro.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "senha" do
    it "é obrigatória no cadastro" do
      sem_senha = described_class.new(nome: "Maria Souza", email: "maria@aluno.unb.br",
                                      senha: "", senha_confirmation: "")

      expect(sem_senha).not_to be_valid
      expect(sem_senha.errors[:senha]).to eq([ "A senha é obrigatória" ])
    end

    it "precisa ter no mínimo 6 caracteres" do
      usuario.senha = usuario.senha_confirmation = "12345"

      expect(usuario).not_to be_valid
      expect(usuario.errors[:senha]).to eq([ "A senha deve ter no mínimo 6 caracteres" ])
    end

    it "aceita exatamente 6 caracteres" do
      usuario.senha = usuario.senha_confirmation = "123456"

      expect(usuario).to be_valid
    end

    it "precisa ser igual à confirmação" do
      usuario.senha_confirmation = "outra456"

      expect(usuario).not_to be_valid
      expect(usuario.errors[:senha_confirmation]).to eq([ "A confirmação de senha não confere" ])
    end

    it "não pode passar do limite de 72 bytes do bcrypt" do
      usuario.senha = usuario.senha_confirmation = "a" * 73

      expect(usuario).not_to be_valid
      expect(usuario.errors[:senha]).to eq([ "A senha é longa demais" ])
    end

    it "é guardada apenas como hash" do
      usuario.save!

      expect(usuario.senha_digest).to be_present
      expect(usuario.senha_digest).not_to include("senha123")
      expect(usuario.authenticate_senha("senha123")).to eq(usuario)
      expect(usuario.authenticate_senha("errada")).to be(false)
    end
  end

  it "tem as sessões de login removidas junto com ele" do
    usuario.save!
    usuario.sessoes.create!(endereco_ip: "127.0.0.1", user_agent: "RSpec")

    expect { usuario.destroy }.to change(Sessao, :count).by(-1)
  end
end
