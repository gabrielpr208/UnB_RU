require "rails_helper"

RSpec.describe Acesso, type: :model do
  let(:estudante) { criar_estudante }

  subject(:acesso) { described_class.new(estudante:, data_hora: Time.zone.local(2026, 10, 12, 12), valor_cobrado: 4.5) }

  it "é válido com estudante, data e hora e valor cobrado" do
    expect(acesso).to be_valid
  end

  it "exige a data e hora" do
    acesso.data_hora = nil

    expect(acesso).not_to be_valid
    expect(acesso.errors[:data_hora]).to be_present
  end

  [ nil, 0, -4.5 ].each do |valor|
    it "recusa o valor cobrado #{valor.inspect}" do
      acesso.valor_cobrado = valor

      expect(acesso).not_to be_valid
      expect(acesso.errors[:valor_cobrado]).to be_present
    end
  end

  it "exige valor cobrado positivo também no banco de dados" do
    acesso.save!

    expect { acesso.update_column(:valor_cobrado, 0) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "é removido junto com o estudante" do
    acesso.save!

    expect { estudante.destroy }.to change(described_class, :count).by(-1)
  end
end
