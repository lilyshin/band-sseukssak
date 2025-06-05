defmodule BandCore.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # 웹 서버 제거, 필요한 서비스만 시작
    ]

    opts = [strategy: :one_for_one, name: BandCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end