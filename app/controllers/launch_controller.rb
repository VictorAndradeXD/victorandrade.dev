# Porta de entrada do app instalado no celular (o start_url do manifest).
#
# O ícone é um só, mas quem toca nele pode ter acesso só ao Denfis, só ao
# contábil ou aos dois. Apontar o manifest direto para /denfis jogaria a
# contadora num "você não tem acesso" toda vez que abrisse o app.
class LaunchController < ApplicationController
  allow_unauthenticated_access

  def show
    redirect_to home_path_for(current_user)
  end
end
