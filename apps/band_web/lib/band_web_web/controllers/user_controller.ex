defmodule BandWebWeb.UserController do
  use BandWebWeb, :controller

  @doc """
  사용자 프로필 조회
  """
  def profile(conn, %{"access_token" => access_token} = params) do
    band_key = Map.get(params, "band_key")
    
    case BandCore.get_profile(access_token, band_key) do
      {:ok, profile_data} ->
        json(conn, %{
          success: true,
          data: profile_data
        })
      
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "프로필 조회 실패: #{inspect(reason)}"
        })
    end
  end

  def profile(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "access_token이 필요합니다"
    })
  end

  @doc """
  사용자가 가입한 밴드 목록 조회
  """
  def bands(conn, %{"access_token" => access_token}) do
    case BandCore.get_bands(access_token) do
      {:ok, bands_data} ->
        json(conn, %{
          success: true,
          data: bands_data
        })
      
      {:error, reason} ->
        require Logger
        Logger.error("밴드 목록 조회 실패: #{inspect(reason)}")
        
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "밴드 목록 조회 실패: #{inspect(reason)}"
        })
    end
  end

  def bands(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "access_token이 필요합니다"
    })
  end
end