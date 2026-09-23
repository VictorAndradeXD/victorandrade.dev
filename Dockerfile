# syntax=docker/dockerfile:1
# check=error=true

# Imagem de produção. Construída na máquina de desenvolvimento e enviada pronta
# para o VPS (veja `builder.local` em config/deploy.yml): o servidor de 2 GB não
# tem folga de memória para rodar `bundle install` + `assets:precompile`.
#
# Para rodar local:
#   docker build -t denfis .
#   docker run -d -p 80:80 -e RAILS_MASTER_KEY=<config/master.key> denfis

# Mantenha em sincronia com .ruby-version. O mise atualiza o Ruby da máquina
# sozinho; quando isso acontecer, as duas pontas precisam subir junto, senão a
# imagem passa a ser construída com um Ruby diferente do que você testa local.
ARG RUBY_VERSION=4.0.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Pacotes de runtime:
#   libvips        -> image_processing (variantes do Active Storage)
#   postgresql-client -> libpq, usada pela gem pg
#   libjemalloc2   -> alocador que segura a fragmentação de memória do Ruby.
#                     Em VPS pequeno isso é a diferença entre caber e não caber.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips \
      postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# ---------------------------------------------------------------------------
# Estágio de build: descartado no final, não entra na imagem publicada.
# ---------------------------------------------------------------------------
FROM base AS build

# build-essential e ffi-compiler são exigidos pela gem argon2, que compila a
# biblioteca C do Argon2 na instalação. libpq-dev é para a gem pg.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# SECRET_KEY_BASE_DUMMY evita exigir a master key só para compilar asset.
# Este passo também roda o tailwindcss:build, gerando app/assets/builds.
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---------------------------------------------------------------------------
# Imagem final
# ---------------------------------------------------------------------------
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Usuário sem privilégio. `storage` guarda os anexos do Active Storage e `tmp`
# guarda o file_store do cache — que é onde vive o contador de rate_limit do
# login (veja config/environments/production.rb).
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Thruster cuida de compressão e cache de assets na frente do Puma.
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
