class AddModuleAccessToUsers < ActiveRecord::Migration[8.1]
  def change
    # Quem já existe é usuário do Denfis: mantém o acesso e não ganha o contábil.
    add_column :users, :denfis_access,     :boolean, null: false, default: true
    add_column :users, :accounting_access, :boolean, null: false, default: false

    # Conta sem nenhum módulo consegue entrar e não tem para onde ir. Barrar no
    # banco evita criar esse usuário-fantasma por descuido num console.
    add_check_constraint :users, "denfis_access OR accounting_access",
                         name: "users_has_at_least_one_module"
  end
end
