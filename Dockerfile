FROM elixir:1.11-alpine AS build

# install build dependencies
RUN apk add --no-cache build-base npm git python3 rust cargo


# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config

RUN mix do deps.get, deps.compile

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv/gettext priv/gettext
COPY priv/repo priv/repo
COPY priv/static priv/static
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# compile and build release
COPY lib lib
COPY native/scheduling/src native/scheduling/src
COPY native/scheduling/Cargo.toml native/scheduling/Cargo.toml

# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do compile, release

# prepare release image
FROM alpine:3.13 AS app
RUN apk add --no-cache openssl ncurses-libs rust

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/hyper_schedule ./

ENV HOME=/app

CMD ["bin/hyper_schedule", "start"]