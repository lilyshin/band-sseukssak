defmodule BandWebWeb.BandProxyController do
  use BandWebWeb, :controller

  @moduledoc """
  밴드 API 프록시 컨트롤러
  
  서버에 미리 설정된 토큰을 사용하여 
  사용자가 직접 개발자 등록을 하지 않아도 
  밴드 API를 사용할 수 있도록 프록시 역할을 합니다.
  """

  @doc """
  서버 토큰으로 사용자 밴드 목록 조회
  """
  def get_user_bands(conn, _params) do
    case get_server_access_token() do
      {:ok, access_token} ->
        case BandCore.get_bands(access_token) do
          {:ok, bands_data} ->
            json(conn, %{
              success: true,
              data: bands_data,
              message: "서버 토큰으로 밴드 목록을 조회했습니다"
            })
          
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{
              success: false,
              error: "밴드 목록 조회 실패: #{inspect(reason)}"
            })
        end
      
      {:error, reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{
          success: false,
          error: reason
        })
    end
  end

  @doc """
  서버 토큰으로 특정 밴드의 댓글 삭제
  """
  def delete_band_comments(conn, %{"band_key" => band_key}) do
    case get_server_access_token() do
      {:ok, access_token} ->
        case BandCore.delete_all_comments_in_band(access_token, band_key) do
          {:ok, summary} ->
            json(conn, %{
              success: true,
              message: "댓글 삭제가 완료되었습니다",
              data: summary
            })
          
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{
              success: false,
              error: "댓글 삭제 실패: #{inspect(reason)}"
            })
        end
      
      {:error, reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{
          success: false,
          error: reason
        })
    end
  end

  @doc """
  서버 토큰으로 사용자 프로필 조회
  """
  def get_user_profile(conn, _params) do
    case get_server_access_token() do
      {:ok, access_token} ->
        case BandCore.get_profile(access_token) do
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
      
      {:error, reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{
          success: false,
          error: reason
        })
    end
  end

  @doc """
  간편 인증 상태 확인
  """
  def check_auth_status(conn, _params) do
    case get_server_access_token() do
      {:ok, _access_token} ->
        json(conn, %{
          success: true,
          authenticated: true,
          auth_type: "server_token",
          message: "서버에 설정된 토큰으로 인증됩니다"
        })
      
      {:error, reason} ->
        json(conn, %{
          success: false,
          authenticated: false,
          auth_type: "user_oauth",
          message: reason
        })
    end
  end

  # 서버에 설정된 액세스 토큰 가져오기
  defp get_server_access_token() do
    case Application.get_env(:band_web, :band_access_token) do
      nil ->
        {:error, "서버에 밴드 액세스 토큰이 설정되지 않았습니다. 환경변수 BAND_ACCESS_TOKEN을 설정해주세요."}
      
      "" ->
        {:error, "밴드 액세스 토큰이 비어있습니다."}
      
      token when is_binary(token) ->
        {:ok, token}
    end
  end
end