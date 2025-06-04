defmodule BandWebWeb.MaintenancePlug do
  @moduledoc """
  정비 모드 플러그
  
  환경 변수나 설정을 통해 정비 모드를 활성화할 수 있습니다.
  정비 모드가 활성화되면 모든 요청을 정비 페이지로 리다이렉트합니다.
  
  ## 사용법
  
  환경 변수로 활성화:
  ```bash
  export MAINTENANCE_MODE=true
  mix phx.server
  ```
  
  또는 config에서 설정:
  ```elixir
  config :band_web, :maintenance_mode, true
  ```
  """
  
  import Plug.Conn
  import Phoenix.Controller

  def init(default), do: default

  def call(conn, _default) do
    if maintenance_mode_enabled?() and not maintenance_path?(conn) do
      conn
      |> redirect(to: "/maintenance")
      |> halt()
    else
      conn
    end
  end

  defp maintenance_mode_enabled? do
    # 환경 변수 확인
    System.get_env("MAINTENANCE_MODE") == "true" or
    # 또는 설정 확인
    Application.get_env(:band_web, :maintenance_mode, false)
  end

  defp maintenance_path?(conn) do
    conn.request_path == "/maintenance"
  end
end