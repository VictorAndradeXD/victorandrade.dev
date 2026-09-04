# victorandrade.dev

Site pessoal de [Victor Andrade](https://github.com/VictorAndradeXD): portfólio,
blog e **Denfis**, um gerenciador de finanças pessoais. Uma aplicação Rails só,
em que cada parte é uma seção do site.

Hoje o Denfis está pronto; portfólio e blog vêm em seguida.

## Denfis

Gestão financeira para uso próprio, com duas contas independentes.

- **Lançamentos** de entrada e saída, com conta, tag e data.
- **Detalhamento por dentro do lançamento.** Uma fatura de cartão de R$ 3.000
  pode ser aberta em "gasolina R$ 1.000", deixando R$ 2.000 sem descrição. A
  soma das partes nunca ultrapassa o total — validado no modelo e garantido no
  banco por uma check constraint.
- **Recorrências** (aluguel, plano de saúde) mensais, semanais ou anuais. A
  geração é idempotente: reexecutar não duplica lançamento.
- **Parcelamentos.** A sobra do arredondamento vai na primeira parcela, então a
  soma das parcelas bate com o total exato.
- **Dashboard** com resultado do período, calendário de saldo diário (cada dia
  abre um modal com os lançamentos daquele dia) e distribuição por tag.
- **Extrato** filtrável com saldo acumulado linha a linha, pronto para imprimir.

### Decisões de projeto

**Dark-first.** A paleta escura é a base, não uma variante: é o que vale sem
atributo nenhum no `<html>`. O modo claro é opcional e fica gravado no
navegador.

**Isolamento por usuário.** Todo controller entra por `current_user.recurso`, e
os modelos validam que conta e tag pertencem ao mesmo dono — forjar um `id` no
formulário não cruza dados entre as duas contas.

**Autenticação.** Argon2id (64 MiB, ~200ms por hash) no lugar do BCrypt, com
duas camadas contra força bruta: rate limit por IP e bloqueio por conta, que
continua valendo quando o atacante troca de endereço. O caminho de e-mail
inexistente gasta o mesmo tempo de um hash real, para o tempo de resposta não
denunciar quais contas existem.

## Stack

Ruby on Rails 8.1 · PostgreSQL 18 · Hotwire (Turbo + Stimulus) · Tailwind CSS 4

Sem SPA e sem build de front separado: o servidor entrega HTML e o Turbo cuida
da navegação.

## Rodando local

Requisitos: Ruby 4.0 (via [mise](https://mise.jdx.dev)) e Docker.

```bash
docker compose up -d          # PostgreSQL na 5432
bin/rails db:prepare          # cria o banco e aplica as migrations
bin/rails db:seed             # primeiro usuário (a senha é impressa uma vez)
bin/dev                       # http://localhost:3000
```

Para popular com dados fictícios variados e ver as telas cheias:

```bash
bin/rails denfis:demo         # apaga os dados financeiros do usuário e recria
```

Outros comandos:

```bash
bin/rails 'denfis:create_user[email@exemplo.com]'   # cria o segundo usuário
bin/rails denfis:materialize_recurring              # gera as recorrências do mês
bin/rubocop                                          # lint
```

## Licença

MIT — veja [LICENSE](LICENSE).
