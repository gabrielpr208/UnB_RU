require "rails_helper"

RSpec.describe Restaurante, type: :model do
  def novo_restaurante(**atributos)
    described_class.new(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro", **atributos)
  end

  def erros(restaurante, atributo)
    restaurante.validate
    restaurante.errors[atributo]
  end

  it "é válido com nome e campus" do
    expect(novo_restaurante).to be_valid
  end

  describe "nome" do
    it "é obrigatório" do
      expect(erros(novo_restaurante(nome: ""), :nome)).to eq([ "O nome é obrigatório" ])
      expect(erros(novo_restaurante(nome: "   "), :nome)).to eq([ "O nome é obrigatório" ])
    end

    it "aceita de 3 a 50 caracteres" do
      expect(novo_restaurante(nome: "FUP")).to be_valid
      expect(novo_restaurante(nome: "a" * 50)).to be_valid
    end

    it "recusa menos de 3 ou mais de 50 caracteres" do
      expect(erros(novo_restaurante(nome: "RU"), :nome)).to eq([ "O nome deve ter entre 3 e 50 caracteres" ])
      expect(erros(novo_restaurante(nome: "a" * 51), :nome)).to eq([ "O nome deve ter entre 3 e 50 caracteres" ])
    end

    it "tira espaços sobrando antes de validar" do
      restaurante = novo_restaurante(nome: "  RU   Gama ")

      expect(restaurante.nome).to eq("RU Gama")
    end

    it "é único, sem diferenciar maiúsculas de minúsculas" do
      novo_restaurante.save!

      expect(erros(novo_restaurante, :nome)).to eq([ "Já existe um restaurante com este nome" ])
      expect(erros(novo_restaurante(nome: "ru darcy ribeiro"), :nome)).to eq([ "Já existe um restaurante com este nome" ])
    end
  end

  describe "campus" do
    it "é obrigatório" do
      expect(erros(novo_restaurante(campus: ""), :campus)).to eq([ "O campus é obrigatório" ])
    end

    it "aceita os quatro campi da UnB" do
      Restaurante::CAMPI.each do |campus|
        expect(novo_restaurante(campus:)).to be_valid
      end
    end

    it "recusa outro campus" do
      expect(erros(novo_restaurante(campus: "Taguatinga"), :campus)).to eq([ "Campus inválido" ])
    end
  end

  describe "#remover" do
    let!(:restaurante) { novo_restaurante.tap(&:save!) }

    it "remove o restaurante sem catracas" do
      expect(restaurante.remover).to be_truthy
      expect(described_class.exists?(restaurante.id)).to be(false)
    end

    it "não remove o restaurante com catracas e explica o motivo" do
      restaurante.catracas.create!(identificador: "01")

      expect(restaurante.remover).to be(false)
      expect(restaurante.errors[:base]).to eq([ "Não é possível remover um restaurante com catracas cadastradas" ])
      expect(described_class.exists?(restaurante.id)).to be(true)
    end

    it "também barra a remoção direta com destroy quando há catracas" do
      restaurante.catracas.create!(identificador: "01")

      expect { restaurante.destroy }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end
  end

  it "lista em ordem alfabética" do
    described_class.create!(nome: "RU Gama", campus: "Gama")
    described_class.create!(nome: "FUP", campus: "Planaltina")

    expect(described_class.em_ordem.map(&:nome)).to eq([ "FUP", "RU Gama" ])
  end
end
