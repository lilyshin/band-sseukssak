defmodule BandApiWeb.AuthController do
  use BandApiWeb, :controller

  @doc """
  Band OAuth 인증 URL 생성
  """
  def auth_url(conn, _params) do
    client_id = Application.get_env(:band_api, :band_app_client_id)
    redirect_uri = "http://localhost:4000/api/auth/oauth/callback"
    
    require Logger
    Logger.info("Auth URL 요청 - client_id: #{inspect(client_id)}")
    
    case client_id do
      nil ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "클라이언트 ID가 설정되지 않았습니다. 환경변수 BAND_CLIENT_ID를 설정하거나 config/dev.exs를 확인하세요."})
      
      "your_client_id_here" ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "실제 밴드 클라이언트 ID를 설정해주세요. 현재 더미 값이 설정되어 있습니다."})
      
      client_id ->
        auth_url = BandAccounts.OAuth.get_auth_url(client_id, redirect_uri)
        json(conn, %{success: true, data: %{auth_url: auth_url}})
    end
  end

  @doc """
  OAuth 콜백 처리 (GET/POST 둘 다 지원)
  
  밴드 인증 서버에서 리다이렉트된 요청을 처리합니다.
  성공 시 authorization code를 받아서 access token을 발급받습니다.
  """
  def oauth_callback(conn, params) do
    case BandAccounts.OAuth.handle_callback(params) do
      {:ok, %{code: code}} ->
        # authorization code를 받았으면 바로 access token 발급
        case BandAccounts.OAuth.get_access_token(%{"code" => code}) do
          {:ok, token_data} ->
            # 프론트엔드로 리다이렉트하면서 토큰 정보를 URL 파라미터로 전달
            query_params = URI.encode_query(%{
              "success" => "true",
              "access_token" => token_data["access_token"],
              "user_key" => token_data["user_key"],
              "expires_in" => token_data["expires_in"],
              "token_type" => token_data["token_type"],
              "scope" => token_data["scope"]
            })
            
            redirect(conn, external: "http://localhost:3000?#{query_params}")
          {:error, reason} ->
            # 에러 시에도 프론트엔드로 리다이렉트
            query_params = URI.encode_query(%{
              "success" => "false",
              "error" => "토큰 발급 실패: #{inspect(reason)}"
            })
            redirect(conn, external: "http://localhost:3000?#{query_params}")
        end
      
      {:error, reason} ->
        # 에러 시에도 프론트엔드로 리다이렉트
        query_params = URI.encode_query(%{
          "success" => "false", 
          "error" => "인증 실패: #{inspect(reason)}"
        })
        redirect(conn, external: "http://localhost:3000?#{query_params}")
    end
  end


  @doc """
  직접 토큰 발급 요청 처리
  
  클라이언트에서 authorization code를 받아서 직접 토큰을 요청할 때 사용합니다.
  """
  def get_token(conn, params) do
    case BandAccounts.OAuth.get_access_token(params) do
      {:ok, token_info} ->
        json(conn, %{success: true, data: token_info})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: reason})
    end
  end
end