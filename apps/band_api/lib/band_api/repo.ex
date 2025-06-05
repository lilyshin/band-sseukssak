defmodule BandApi.Repo do
  use Ecto.Repo,
    otp_app: :band_api,
    adapter: Ecto.Adapters.Postgres
end
