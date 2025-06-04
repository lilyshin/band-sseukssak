defmodule BandWebWeb.AuthController do
  use BandWebWeb, :controller

  @moduledoc """
  Band OAuth 인증 컨트롤러
  
  서버에 미리 설정된 공용 OAuth 앱 정보를 사용하여
  사용자가 별도의 개발자 등록 없이 로그인할 수 있도록 합니다.
  """

  @doc """
  Band OAuth 인증 URL 생성 (서버 설정 기반)
  """
  def auth_url(conn, _params) do
    case get_server_oauth_config() do
      {:ok, {client_id, _client_secret}} ->
        redirect_uri = get_redirect_uri(conn)
        auth_url = BandAccounts.get_auth_url(client_id, redirect_uri)
        
        json(conn, %{
          success: true,
          auth_url: auth_url,
          message: "서버에 설정된 공용 OAuth 앱을 사용합니다"
        })
      
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
  OAuth 콜백 처리 및 토큰 발급 (서버 설정 기반)
  GET 및 POST 요청 모두 처리
  """
  def callback(conn, params) do
    # GET 요청의 경우 쿼리 파라미터에서, POST 요청의 경우 body에서 code 추출
    code = params["code"]
    
    if code do
      # GET 요청인 경우 토큰을 바로 처리하고 HTML로 결과 전달
      if conn.method == "GET" do
        case get_server_oauth_config() do
          {:ok, {client_id, client_secret}} ->
            case BandAccounts.get_access_token(client_id, client_secret, code) do
              {:ok, token_data} ->
                render_callback_success(conn, token_data)
              
              {:error, {_status_code, error_data}} ->
                render_callback_error(conn, "토큰 발급 실패: #{inspect(error_data)}")
              
              {:error, reason} ->
                render_callback_error(conn, "토큰 발급 실패: #{inspect(reason)}")
            end
          
          {:error, reason} ->
            render_callback_error(conn, reason)
        end
      else
        # POST 요청인 경우 JSON 응답
        process_callback(conn, code)
      end
    else
      if conn.method == "GET" do
        render_callback_error(conn, "authorization code가 없습니다")
      else
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "authorization code가 필요합니다"
        })
      end
    end
  end

  # 실제 콜백 처리 로직
  defp process_callback(conn, code) do
    case get_server_oauth_config() do
      {:ok, {client_id, client_secret}} ->
        case BandAccounts.get_access_token(client_id, client_secret, code) do
          {:ok, token_data} ->
            json(conn, %{
              success: true,
              data: token_data,
              message: "서버 OAuth 앱으로 토큰을 발급받았습니다"
            })
          
          {:error, {status_code, error_data}} ->
            conn
            |> put_status(status_code)
            |> json(%{
              success: false,
              error: error_data
            })
          
          {:error, reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{
              success: false,
              error: "토큰 발급 실패: #{inspect(reason)}"
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

  # 서버에 설정된 OAuth 설정 가져오기
  defp get_server_oauth_config() do
    client_id = Application.get_env(:band_web, :band_app_client_id)
    client_secret = Application.get_env(:band_web, :band_app_client_secret)

    case {client_id, client_secret} do
      {nil, _} -> 
        {:error, "서버에 BAND_CLIENT_ID가 설정되지 않았습니다. 관리자에게 문의하세요."}
      
      {_, nil} -> 
        {:error, "서버에 BAND_CLIENT_SECRET이 설정되지 않았습니다. 관리자에게 문의하세요."}
      
      {"", _} -> 
        {:error, "BAND_CLIENT_ID가 비어있습니다."}
      
      {_, ""} -> 
        {:error, "BAND_CLIENT_SECRET이 비어있습니다."}
      
      {id, secret} when is_binary(id) and is_binary(secret) -> 
        {:ok, {id, secret}}
    end
  end

  # Redirect URI 자동 생성
  defp get_redirect_uri(conn) do
    scheme = if conn.scheme == :https, do: "https", else: "http"
    host = conn.host
    port = conn.port
    
    # 표준 포트가 아닌 경우에만 포트 번호 포함
    host_with_port = case {scheme, port} do
      {"http", 80} -> host
      {"https", 443} -> host
      _ -> "#{host}:#{port}"
    end
    
    "#{scheme}://#{host_with_port}/api/auth/band/callback"
  end

  # GET 콜백 성공시 HTML 응답
  defp render_callback_success(conn, token_data) do
    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>🧹 밴쓱싹 - 로그인 완료!</title>
      <meta charset="utf-8">
    </head>
    <body>
      <script>
        // 토큰 데이터를 localStorage에 저장
        const tokenData = #{Jason.encode!(token_data)};
        localStorage.setItem('band_auth_data', JSON.stringify(tokenData));
        
        // 부모 창으로 이동 (새 탭에서 열린 경우)
        if (window.opener) {
          window.opener.location.reload();
          window.close();
        } else {
          // 같은 창에서 열린 경우 홈으로 이동
          window.location.href = '/';
        }
      </script>
      <div style="text-align: center; padding: 50px; font-family: Arial;">
        <h1>🧹 로그인 완료!</h1>
        <p>잠시만 기다려주세요...</p>
      </div>
    </body>
    </html>
    """
    
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  # GET 콜백 실패시 HTML 응답
  defp render_callback_error(conn, error_message) do
    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>🧹 밴쓱싹 - 로그인 실패</title>
      <meta charset="utf-8">
    </head>
    <body>
      <script>
        // 부모 창으로 이동 (새 탭에서 열린 경우)
        if (window.opener) {
          window.opener.location.href = '/?error=' + encodeURIComponent('#{error_message}');
          window.close();
        } else {
          // 같은 창에서 열린 경우 홈으로 이동
          window.location.href = '/?error=' + encodeURIComponent('#{error_message}');
        }
      </script>
      <div style="text-align: center; padding: 50px; font-family: Arial;">
        <h1>😢 로그인 실패</h1>
        <p>#{error_message}</p>
        <p>잠시만 기다려주세요...</p>
      </div>
    </body>
    </html>
    """
    
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(400, html)
  end
end