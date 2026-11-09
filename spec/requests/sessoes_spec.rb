require "rails_helper"

RSpec.describe "Login do estudante", type: :request do
  describe "GET /login" do
    it "exibe a página de login" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Login do estudante")
      expect(response.body).to include(%(href="#{cadastro_path}"))
    end
  end
end
