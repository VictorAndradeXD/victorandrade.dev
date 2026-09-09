require "test_helper"

class DenfisAccessFlowTest < ActionDispatch::IntegrationTest
  test "visitante deslogado em /denfis vai para o login e volta para /denfis depois de entrar" do
    get denfis_root_path
    assert_redirected_to new_session_path

    user = User.take
    post session_path, params: { email_address: user.email_address, password: "password" }

    assert_redirected_to denfis_root_path
  end

  test "deslogado num caminho interno volta para aquele caminho, nao para a raiz do denfis" do
    get transactions_path
    assert_redirected_to new_session_path

    user = User.take
    post session_path, params: { email_address: user.email_address, password: "password" }

    assert_redirected_to transactions_path
  end

  test "logado, /denfis abre normalmente" do
    sign_in_as User.take
    get denfis_root_path

    assert_response :success
  end
end
