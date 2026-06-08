FROM hexpm/elixir:1.15.7-erlang-26.1.2-debian-bookworm-20231009-slim AS builder

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential git && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config
COPY lib lib
COPY priv priv

FROM builder AS release

ENV MIX_ENV=prod
RUN mix deps.get --only prod && mix compile && mix release

FROM debian:bookworm-slim

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libstdc++6 openssl ca-certificates curl postgresql-client && rm -rf /var/lib/apt/lists/*

RUN groupadd -r app && useradd -r -g app app

WORKDIR /app
COPY --from=release /app/_build/prod/rel/api ./
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
RUN chown -R app:app /app

USER app
EXPOSE 4000

ENTRYPOINT ["/app/entrypoint.sh"]
