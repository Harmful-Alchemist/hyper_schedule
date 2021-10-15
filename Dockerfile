FROM elixir:1.12-alpine AS build

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
COPY priv/gettext priv/gettext
COPY priv/repo priv/repo
COPY assets assets
# Tailwind scans files in the lib dir to purge the css classes
COPY lib lib
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
RUN npm run --prefix ./assets deploy
COPY native/scheduling/src native/scheduling/src
COPY native/scheduling/Cargo.toml native/scheduling/Cargo.toml
RUN mix phx.digest

# compile and build release
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
# Migrate by  bin/hyper_schedule eval "HyperSchedule.Release.migrate"
CMD ["bin/hyper_schedule", "start"]