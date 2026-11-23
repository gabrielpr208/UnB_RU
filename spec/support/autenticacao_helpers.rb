module AutenticacaoHelpers
  def entrar_como(estudante, senha: "senha123")
    post login_path, params: { login: { matricula: estudante.matricula, senha: } }
  end

  def entrar_como_funcionario(funcionario, senha: "senha123")
    post login_controle_path, params: { login: { siape: funcionario.siape, senha: } }
  end
end

RSpec.configure do |config|
  config.include AutenticacaoHelpers, type: :request
end
