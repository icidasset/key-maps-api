use Mix.Config


config :key_maps, KeyMaps.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "key_maps_test",
  username: "icidasset",
  password: "",
  pool: Ecto.Adapters.SQL.Sandbox


config :logger,
  level: :info
