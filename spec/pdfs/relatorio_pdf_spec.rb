require "rails_helper"

RSpec.describe RelatorioPdf do
  let!(:darcy) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
  let!(:gama) { Restaurante.create!(nome: "RU Gama", campus: "Gama") }
  let!(:fce) { Restaurante.create!(nome: "RU FCE", campus: "Ceilândia") }

  # Linhas entre o título e o rodapé, sem os espaços que o PDF usa para alinhar as colunas das tabelas.
  def linhas_do_conteudo
    texto = PDF::Reader.new(StringIO.new(described_class.new.render)).pages.map(&:text).join("\n")
    linhas = texto.lines.map(&:squish).reject(&:empty?)
    linhas[(linhas.index("Relatório Global de Operação") + 1)...linhas.index { |l| l.start_with?("Gerado em") }]
  end

  it "mostra os totais por restaurante e depois os acessos, do mais recente para o mais antigo" do
    maria = criar_estudante(matricula: "231012345", email: "maria@aluno.unb.br")
    joao = criar_estudante(matricula: "221054321", email: "joao@aluno.unb.br")
    maria.acessos.create!(valor_cobrado: 4.5, data_hora: Time.zone.local(2026, 10, 16, 12, 30),
                          catraca: darcy.catracas.create!(identificador: "01"))
    joao.acessos.create!(valor_cobrado: 4.5, data_hora: Time.zone.local(2026, 10, 15, 18, 45),
                         catraca: darcy.catracas.create!(identificador: "02"))
    joao.acessos.create!(valor_cobrado: 4.5, data_hora: Time.zone.local(2026, 10, 15, 12, 5),
                         catraca: gama.catracas.create!(identificador: "01"))

    expect(linhas_do_conteudo).to eq([
      "Totais por restaurante",
      "RESTAURANTE ACESSOS",
      "RU Darcy Ribeiro 2",
      "RU Gama 1",
      "RU FCE 0",
      "Total geral 3",
      "Acessos",
      "ESTUDANTE RESTAURANTE CATRACA DATA E HORA",
      "231012345 RU Darcy Ribeiro 01 16/10/2026 12:30",
      "221054321 RU Darcy Ribeiro 02 15/10/2026 18:45",
      "221054321 RU Gama 01 15/10/2026 12:05"
    ])
  end

  it "sem acessos, mostra os totais zerados e avisa que não há acessos no lugar da tabela" do
    expect(linhas_do_conteudo).to eq([
      "Totais por restaurante",
      "RESTAURANTE ACESSOS",
      "RU Darcy Ribeiro 0",
      "RU FCE 0",
      "RU Gama 0",
      "Total geral 0",
      "Acessos",
      "Nenhum acesso registrado."
    ])
  end
end
