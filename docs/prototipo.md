# Protótipo antes do servidor

Dois jeitos de alguém testar o app enquanto o VPS não existe, os dois pensados
para que os dados subam para o servidor depois sem retrabalho.

| | Celular (PWA) | Windows (instalador) |
|---|---|---|
| Onde roda | nesta máquina, exposta pelo `bin/share` | no PC da pessoa |
| Banco | `denfis_prototipo`, no Postgres local | Postgres portátil dentro do instalador |
| IDs | faixa baixa (1, 2, 3...) | a partir de 1.000.000.000 |
| Ida para o servidor | restauração inteira | soma ao que já estiver lá |

As faixas de ID separadas são o que permite juntar os dois bancos no servidor
sem remapear chave nenhuma (`lib/tasks/prototipo.rake`).

## Celular

```bash
bin/share
```

O script imprime a URL do túnel e o comando para criar a conta de quem vai
testar — **com** `DENFIS_DATABASE_NAME=denfis_prototipo`; sem isso a conta nasce
no banco de desenvolvimento e a pessoa não entra.

No Android, a pessoa abre a URL no Chrome e usa **⋮ → Adicionar à tela inicial**
(ou "Instalar app"). O ícone abre em tela cheia, em `/app`, que leva cada um ao
módulo que pode abrir. Sem internet aparece uma página de "sem conexão"; nenhuma
tela com dados fica guardada no celular.

Limites do túnel: a URL muda a cada `bin/share` (o ícone instalado aponta para
a antiga — é preciso instalar de novo) e só funciona com esta máquina ligada.

Backup do banco do protótipo, fora do repositório:

```bash
bin/backup            # → ~/Backups/denfis/denfis_prototipo-AAAAMMDD-HHMMSS.dump
```

## Windows

### Gerar o instalador

GitHub → Actions → **Instalador Windows** → Run workflow (ou `gh workflow run
windows.yml`). O run compila as gems num Windows, monta o pacote, instala numa
máquina limpa e faz o primeiro acesso inteiro antes de liberar o artefato:

```bash
gh run download --name Denfis-Setup     # Denfis-Setup.exe
```

### O que a pessoa faz

1. Roda `Denfis-Setup.exe`. O Windows avisa "o Windows protegeu o computador"
   porque o instalador não é assinado: **Mais informações → Executar assim mesmo**.
2. Informa o e-mail e se vai usar o módulo contábil. Não pede administrador.
3. Abre o atalho **Denfis**. Uma janela preta liga tudo e o navegador abre na
   tela de criar a senha (o link vale 15 minutos; se passar, é só fechar a janela
   e abrir o Denfis de novo).
4. Usa no navegador, em `http://localhost:3210`. Para desligar, fecha a janela.

A cada início o lançador grava um backup em **Documentos\Denfis\Backups** (os 30
mais recentes ficam). Há também os atalhos **Fazer backup do Denfis** e **Pasta
de backups do Denfis** no menu Iniciar.

Atualizar = rodar um instalador mais novo por cima: o banco fica em
`%LOCALAPPDATA%\Denfis` e não é tocado. Desinstalar também não apaga os dados.

### Peças

- `packaging/windows/denfis.rb` — o lançador: Postgres, migrations, Puma, backups.
  Roda no Linux também, para teste (variáveis `DENFIS_*` no topo).
- `packaging/windows/denfis.iss` — o instalador (Inno Setup). Precisa ficar em
  UTF-8 **com BOM**, senão os acentos saem quebrados.
- `packaging/windows/teste_fumaca.rb` — o primeiro acesso, como o CI o executa.
- `config/environments/desktop.rb` — produção sem SSL, sem SMTP, só localhost.

## Subir para o servidor

Na ordem: primeiro o protótipo inteiro, depois o Windows somado a ele.

**1. O banco do protótipo vira o banco de produção.** Logo depois do primeiro
deploy, com o app parado:

```bash
bin/backup
scp ~/Backups/denfis/denfis_prototipo-*.dump vps:/tmp/prototipo.dump
kamal app stop
ssh vps 'docker cp /tmp/prototipo.dump denfis-db:/tmp/ &&
         docker exec denfis-db pg_restore -U denfis -d denfis_production --clean --if-exists --no-owner /tmp/prototipo.dump'
kamal app boot
```

O `--clean` substitui tudo, inclusive o `admin@app.test` que o seed do primeiro
deploy cria.

**2. O backup do Windows entra somado.** A pessoa envia o `.dump` mais recente da
pasta de backups. Antes, servidor e Windows precisam estar na mesma versão do
schema: faça o deploy e abra o Denfis do Windows uma vez com o instalador
correspondente.

```bash
scp bin/mesclar-backup denfis-20261101-093000.dump vps:/tmp/
ssh vps 'CONTAINER=denfis-db DB=denfis_production /tmp/mesclar-backup /tmp/denfis-20261101-093000.dump'
```

Entram os usuários e os dados deles; ficam de fora as tabelas fiscais, as
sessões e os metadados. Tudo numa transação só: se o e-mail já existir no
servidor ou algo falhar, nada é gravado. A senha que a pessoa criou no Windows
continua valendo.

**Cuidado com o contábil:** empresas não são por usuário. Se a mesma empresa foi
cadastrada no protótipo e no Windows, ela aparece duas vezes depois da soma.
