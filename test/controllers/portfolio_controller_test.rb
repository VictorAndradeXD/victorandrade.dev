require "test_helper"

class PortfolioControllerTest < ActionDispatch::IntegrationTest
  test "falls back to English when the browser speaks nothing we do" do
    get root_path, headers: { "Accept-Language" => "es-ES,es;q=0.9,fr;q=0.8" }

    assert_response :success
    assert_select "html[lang=?]", "en"
  end

  test "falls back to English when the browser sends no preference" do
    get root_path

    assert_select "html[lang=?]", "en"
  end

  test "follows the browser language" do
    get root_path, headers: { "Accept-Language" => "pt-BR,pt;q=0.9,en;q=0.8" }

    assert_select "html[lang=?]", "pt-BR"
  end

  test "any Portuguese variant lands on pt-BR" do
    get root_path, headers: { "Accept-Language" => "pt-PT" }

    assert_select "html[lang=?]", "pt-BR"
  end

  test "ranks by quality, not by position in the header" do
    get root_path, headers: { "Accept-Language" => "en;q=0.4,pt;q=0.9" }

    assert_select "html[lang=?]", "pt-BR"
  end

  test "an explicit choice beats the browser language" do
    get root_path(locale: "en"), headers: { "Accept-Language" => "pt-BR" }

    assert_select "html[lang=?]", "en"
    assert_equal "en", cookies[:locale]
  end

  test "a choice made earlier beats the browser language" do
    get root_path(locale: "en"), headers: { "Accept-Language" => "pt-BR" }
    get root_path, headers: { "Accept-Language" => "pt-BR" }

    assert_select "html[lang=?]", "en"
  end

  test "an unsupported locale param is ignored" do
    get root_path(locale: "de"), headers: { "Accept-Language" => "pt-BR" }

    assert_select "html[lang=?]", "pt-BR"
    assert_nil cookies[:locale].presence
  end

  test "tells caches the response varies by language" do
    get root_path

    assert_includes response.headers["Vary"], "Accept-Language"
  end

  test "a visitor never sees links into the private apps" do
    get root_path

    assert_select "a[href=?]", denfis_root_path, count: 0
    assert_select "a[href=?]", contabil_path,    count: 0
  end

  test "the owner gets the private app shortcuts once signed in" do
    sign_in_as User.take
    get root_path

    assert_select "a[href=?]", denfis_root_path, count: 1
    assert_select "a[href=?]", contabil_path,    count: 1
  end

  test "the other modules stay in Portuguese whatever the browser asks" do
    get blog_path,     headers: { "Accept-Language" => "en-US,en;q=0.9" }
    assert_select "html[lang=?]", "pt-BR"

    get contabil_path, headers: { "Accept-Language" => "en-US,en;q=0.9" }
    assert_select "html[lang=?]", "pt-BR"
  end
end
