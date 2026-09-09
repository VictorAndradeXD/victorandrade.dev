require "test_helper"

class UserModuleAccessTest < ActiveSupport::TestCase
  test "o banco recusa um usuário sem nenhum módulo" do
    user = users(:one)

    assert_raises ActiveRecord::StatementInvalid do
      user.update_columns(denfis_access: false, accounting_access: false)
    end
  end

  test "acesso aos dois módulos é permitido" do
    user = users(:one)
    user.update_columns(denfis_access: true, accounting_access: true)

    assert user.reload.denfis_access?
    assert user.accounting_access?
  end

  test "usuário novo nasce com Denfis e sem contábil" do
    user = User.create!(email_address: "novo@example.com",
                        password: "senhaSuperLonga1", password_confirmation: "senhaSuperLonga1")

    assert user.denfis_access?
    assert_not user.accounting_access?
  end
end
