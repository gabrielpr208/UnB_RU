module AutenticacaoHelpers
  def entrar_como(estudante, senha: "senha123")
    post login_path, params: { login: { matricula: estudante.matricula, senha: } }
  end
end

RSpec.configure do |config|
  config.include AutenticacaoHelpers, type: :request
end
