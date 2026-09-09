require "test_helper"

class AccountingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @contadora = users(:contadora)
    @dono      = users(:one)
  end

  test "visitante deslogado é mandado para o login" do
    get contabil_path

    assert_redirected_to new_session_path
  end

  test "a tela de login se identifica como Contábil para quem vinha de lá" do
    get contabil_path
    follow_redirect!

    assert_select "h1", "Contábil"
  end

  test "a tela de login segue sendo do Denfis para quem vinha do Denfis" do
    get denfis_root_path
    follow_redirect!

    assert_select "h1", "Denfis"
  end

  test "a contadora entra e cai no contábil, não no Denfis" do
    get contabil_path
    post session_path, params: { email_address: @contadora.email_address, password: "password" }

    assert_redirected_to contabil_path
  end

  test "sem destino guardado, cada um cai no seu próprio módulo" do
    post session_path, params: { email_address: @contadora.email_address, password: "password" }
    assert_redirected_to contabil_path

    delete session_path
    post session_path, params: { email_address: @dono.email_address, password: "password" }
    assert_redirected_to denfis_root_path
  end

  test "a contadora abre o contábil" do
    sign_in_as @contadora
    get contabil_path

    assert_response :success
  end

  test "a contadora não entra no Denfis" do
    sign_in_as @contadora
    get denfis_root_path

    assert_redirected_to contabil_path
    assert_equal "Você não tem acesso ao Denfis.", flash[:alert]
  end

  test "a contadora não entra em nenhuma tela interna do Denfis" do
    sign_in_as @contadora

    [ transactions_path, accounts_path, tags_path, statement_path,
      recurring_rules_path, installment_plans_path ].each do |path|
      get path
      assert_redirected_to contabil_path, "#{path} deixou a contadora passar"
    end
  end

  test "o dono do Denfis não entra no contábil" do
    sign_in_as @dono
    get contabil_path

    assert_redirected_to denfis_root_path
    assert_equal "Você não tem acesso ao módulo contábil.", flash[:alert]
  end

  test "o rodapé do portfólio oferece só o módulo de quem está logado" do
    sign_in_as @contadora
    get root_path

    assert_select "a[href=?]", contabil_path,    count: 1
    assert_select "a[href=?]", denfis_root_path, count: 0
  end
end
