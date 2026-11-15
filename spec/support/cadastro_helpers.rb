module CadastroHelpers
  def dados_validos_de_cadastro(**alteracoes)
    {
      nome: "Maria Souza",
      matricula: "231012345",
      email: "maria@aluno.unb.br",
      senha: "senha123",
      confirmacao_senha: "senha123"
    }.merge(alteracoes)
  end

  def criar_estudante(matricula: "231012345", email: "existente@aluno.unb.br")
    usuario = Usuario.create!(nome: "Estudante Existente", email:, senha: "senha123")
    Estudante.create!(usuario:, matricula:)
  end

  def criar_funcionario(siape: "1234567", email: "funcionario@unb.br", administrador: false)
    usuario = Usuario.create!(nome: "Funcionário Existente", email:, senha: "senha123")
    Funcionario.create!(usuario:, siape:, administrador:)
  end
end

RSpec.configure do |config|
  config.include CadastroHelpers
end
