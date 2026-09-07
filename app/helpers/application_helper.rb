module ApplicationHelper
  # R$ 1.234,56 — sem depender do locale pt-BR estar instalado.
  def money(value, signed: false)
    amount = value.to_d
    prefix = signed && amount.positive? ? "+" : ""

    prefix + number_to_currency(amount, unit: "R$", delimiter: ".", separator: ",", precision: 2)
  end

  # Valor curto para caber na célula do calendário: sem "R$", e sem centavos
  # a partir de cem reais, onde eles só poluem.
  def compact_money(value)
    amount = value.to_d
    sign = amount.negative? ? "-" : "+"
    precision = amount.abs >= 100 ? 0 : 2

    sign + number_to_currency(amount.abs, unit: "", delimiter: ".", separator: ",", precision: precision).strip
  end

  # "9 de setembro de 2026". O mês vem capitalizado do locale porque é usado
  # sozinho no seletor ("Setembro 2026"); no meio da frase vai minúsculo.
  def long_date(date)
    "#{date.day} de #{I18n.t('date.month_names')[date.month].downcase} de #{date.year}"
  end

  # Verde para entrada, vermelho para saída.
  def amount_color(amount)
    amount.to_d.negative? ? "text-expense" : "text-income"
  end

  def month_label(date)
    "#{I18n.t('date.month_names')[date.month]} #{date.year}"
  end

  # Marca do portfólio: monograma em caixa, para não repetir o losango que já
  # identifica o Denfis. `text-canvas` e não `text-white` porque o brand muda de
  # tom entre os temas — o canvas é o único que contrasta nos dois.
  def brand_mark
    tag.span "JV",
      class: "inline-flex items-center justify-center w-7 h-7 rounded-lg bg-brand " \
             "text-canvas text-xs font-bold tracking-tight shrink-0",
      aria: { hidden: true }
  end

  # Bandeiras do seletor de idioma. SVG inline em vez de emoji porque emoji de
  # bandeira não renderiza no Chrome do Windows: sai como as letras "BR"/"US".
  def flag_icon(locale)
    body = locale == "pt-BR" ? brazil_flag_body : usa_flag_body

    attrs = 'viewBox="0 0 28 20" class="w-5 h-[0.9rem] rounded-[2px] block" aria-hidden="true"'
    "<svg #{attrs}>#{body}</svg>".html_safe
  end

  # Menu do site público. Separado do nav_link_to do Denfis porque aqui os
  # destinos são âncoras (/#work): o current_page? do Rails ignora o fragmento,
  # então todas elas acenderiam ao mesmo tempo na home.
  def site_link_to(name, path)
    active = path.exclude?("#") && current_page?(path)
    classes = active ? "text-ink bg-elevated" : "text-muted hover:text-ink"
    link_to name, path, class: "px-3 py-1.5 rounded-lg transition-colors whitespace-nowrap #{classes}"
  end

  # O botão do currículo só aparece com o PDF de fato em public/, para não
  # deixar um link quebrado no ar.
  def resume_available?
    Rails.root.join("public", Portfolio::RESUME_PATH.delete_prefix("/")).exist?
  end

  # Link de navegação que se destaca na seção ativa.
  def nav_link_to(name, path)
    classes = current_page?(path) ? "text-ink bg-elevated" : "text-muted hover:text-ink"
    link_to name, path, class: "px-3 py-1.5 rounded-lg transition-colors #{classes}"
  end

  # Contas que o usuário pode escolher num lançamento. Memoizado porque a mesma
  # lista decide o layout do formulário e o conteúdo do campo.
  def selectable_accounts
    @selectable_accounts ||= current_user.accounts.active.order(:name).to_a
  end

  # Com uma conta só o seletor vira atrito: some do formulário e o valor vai
  # escondido. Volta a aparecer assim que existir mais de uma.
  def account_selector_visible?
    selectable_accounts.size != 1
  end

  # Ícones inline (Heroicons, licença MIT). Inline em vez de gem ou sprite:
  # são três, não vale uma dependência nem uma requisição a mais.
  ICON_PATHS = {
    eye: [
      "M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z",
      "M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
    ],
    pencil: [
      "m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125"
    ],
    trash: [
      "m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"
    ],
    refresh: [
      "M16.023 9.348h4.992V4.356m0 4.992-3.181-3.183a8.25 8.25 0 0 0-13.803 3.7M4.031 9.865v4.992m0 0h4.99m-4.99 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7"
    ]
  }.freeze

  # aria-hidden porque o rótulo acessível vive no link/botão que o envolve.
  def action_icon(name)
    paths = ICON_PATHS.fetch(name)
      .map { |d| %(<path stroke-linecap="round" stroke-linejoin="round" d="#{d}"/>) }
      .join

    attrs = 'class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"'

    "<svg #{attrs}>#{paths}</svg>".html_safe
  end

  # Botões de ação de uma linha de lista: só o ícone, com rótulo para leitor de
  # tela e title para quem passa o mouse.
  def icon_button_classes(tone = :neutral)
    hover = tone == :danger ? "hover:text-expense" : "hover:text-ink"
    "text-muted #{hover} transition-colors p-1.5 rounded-lg hover:bg-elevated"
  end

  private
    def brazil_flag_body
      <<~SVG
        <rect width="28" height="20" fill="#009C3B"/>
        <path d="M14 2.6 25.4 10 14 17.4 2.6 10Z" fill="#FFDF00"/>
        <circle cx="14" cy="10" r="4.4" fill="#002776"/>
      SVG
    end

    def usa_flag_body
      stripe = 20.0 / 13
      # Sete faixas vermelhas sobre o fundo branco: 0, 2, 4... é o desenho real.
      stripes = (0..12).step(2).map do |i|
        %(<rect y="#{(i * stripe).round(3)}" width="28" height="#{stripe.round(3)}" fill="#B22234"/>)
      end.join

      canton_h = (stripe * 7).round(3)
      # Nove estrelas em grade: no tamanho que a bandeira é exibida, as 50 reais
      # viram um borrão cinza.
      stars = [ 1.6, 4.0, 6.4, 8.8 ].each_with_index.flat_map do |x, col|
        [ 2.2, 5.4, 8.6 ].each_with_index.map do |y, row|
          next if (col + row).odd?
          %(<circle cx="#{x}" cy="#{y}" r="0.62" fill="#FFFFFF"/>)
        end
      end.compact.join

      %(<rect width="28" height="20" fill="#FFFFFF"/>#{stripes}) +
        %(<rect width="11.2" height="#{canton_h}" fill="#3C3B6E"/>#{stars})
    end
end
