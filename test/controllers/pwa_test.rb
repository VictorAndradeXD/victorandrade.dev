require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "o manifest aponta para a entrada neutra e para ícones que existem" do
    get pwa_manifest_path(format: :json)

    assert_response :success
    manifest = JSON.parse(response.body)

    assert_equal "/app", manifest["start_url"]
    assert_equal "standalone", manifest["display"]

    # O Chrome do Android só oferece a instalação com ícones de 192 e 512.
    sizes = manifest["icons"].map { |icon| icon["sizes"] }
    assert_includes sizes, "192x192"
    assert_includes sizes, "512x512"
    assert manifest["icons"].any? { |icon| icon["purpose"] == "maskable" }

    manifest["icons"].each do |icon|
      assert Rails.public_path.join(icon["src"].delete_prefix("/")).exist?, "ícone ausente: #{icon['src']}"
    end
  end

  test "o service worker é servido e só guarda a página offline" do
    get pwa_service_worker_path(format: :js)

    assert_response :success
    assert_includes response.body, "/offline.html"
    assert Rails.public_path.join("offline.html").exist?
  end

  test "as telas do app anunciam o manifest e o portfólio não" do
    get new_session_path
    assert_select "link[rel=manifest]"

    get root_path
    assert_select "link[rel=manifest]", count: 0
  end

  test "a entrada do app manda quem não entrou para o login" do
    get app_launch_path

    assert_redirected_to new_session_path
  end

  test "a entrada do app manda cada um para o módulo que pode abrir" do
    sign_in_as users(:one)
    get app_launch_path
    assert_redirected_to denfis_root_path

    sign_out
    sign_in_as users(:contadora)
    get app_launch_path
    assert_redirected_to contabil_path
  end
end
