defmodule BandAccounts.OAuth do
  @moduledoc """
  Band OAuth 2.0 인증 구현 모듈
  
  이 모듈은 밴드 오픈 API의 OAuth 2.0 인증 플로우를 구현합니다.
  주요 기능:
  - 인증 URL 생성 (authorization code 획득)
  - Access token 발급 (authorization code → access token)
  - Access token 갱신 (refresh token → new access token)
  
  ## OAuth 2.0 플로우
  1. `get_auth_url/2`로 사용자를 인증 페이지로 리다이렉트
  2. 사용자 동의 후 authorization code 수신
  3. `get_access_token/3`으로 access token 발급
  4. 토큰 만료 시 `refresh_token/3`으로 갱신
  
  ## 에러 처리
  - 네트워크 에러: `{:error, HTTPoison.Error.t()}`
  - HTTP 에러: `{:error, {status_code, error_data}}`
  - JSON 파싱 에러: `{:error, :invalid_response}`
  """

  # Band OAuth 인증 서버의 기본 URL
  # 테스트 환경에서는 Application.get_env로 override 가능
  @auth_base_url Application.compile_env(:band_accounts, :auth_base_url, "https://auth.band.us")

  @doc """
  Band OAuth 2.0 인증 URL 생성
  
  사용자를 밴드 인증 페이지로 리다이렉트하기 위한 URL을 생성합니다.
  사용자가 이 URL에 접속하여 로그인하고 권한을 승인하면,
  지정된 redirect_uri로 authorization code가 전달됩니다.
  
  ## Parameters
  - `client_id`: 밴드 개발자 센터에서 발급받은 클라이언트 ID
  - `redirect_uri`: 인증 완료 후 리다이렉트될 URI (URL 인코딩 자동 처리)
  
  ## Returns
  사용자가 접속해야 할 인증 URL 문자열
  
  ## Examples
      iex> BandAccounts.OAuth.get_auth_url("my_client_id", "https://myapp.com/callback")
      "https://auth.band.us/oauth2/authorize?response_type=code&client_id=my_client_id&redirect_uri=https%3A%2F%2Fmyapp.com%2Fcallback"
  """
  def get_auth_url(client_id, redirect_uri) do
    # OAuth 2.0 표준에 따른 필수 파라미터 구성
    params = 
      URI.encode_query(%{
        response_type: "code",        # OAuth 2.0 Authorization Code Grant 방식
        client_id: client_id,         # 클라이언트 식별자
        redirect_uri: redirect_uri    # 콜백 URI (자동으로 URL 인코딩됨)
      })

    base_url = Application.get_env(:band_accounts, :auth_base_url, @auth_base_url)
    "#{base_url}/oauth2/authorize?#{params}"
  end

  @doc """
  Authorization code를 사용하여 access token 발급
  
  OAuth 2.0 플로우의 두 번째 단계로, 사용자 인증 후 받은 authorization code를
  실제 API 호출에 사용할 수 있는 access token으로 교환합니다.
  
  ## Parameters
  - `client_id`: 클라이언트 ID
  - `client_secret`: 클라이언트 시크릿 (안전하게 보관 필요)
  - `code`: 인증 서버에서 받은 authorization code
  
  ## Returns
  - `{:ok, token_data}`: 성공 시 토큰 정보 (access_token, refresh_token, expires_in 등)
  - `{:error, {status_code, error_data}}`: HTTP 에러 시 상태코드와 에러 정보
  - `{:error, :invalid_response}`: JSON 파싱 실패
  - `{:error, error}`: 네트워크 에러
  
  ## Examples
      {:ok, %{
        "access_token" => "abc123",
        "token_type" => "bearer",
        "refresh_token" => "def456",
        "expires_in" => 315359999,
        "user_key" => "user123"
      }} = BandAccounts.OAuth.get_access_token("client_id", "client_secret", "auth_code")
  """
  def get_access_token(client_id, client_secret, code) do
    base_url = Application.get_env(:band_accounts, :auth_base_url, @auth_base_url)
    url = "#{base_url}/oauth2/token"
    
    # OAuth 2.0 토큰 요청 파라미터
    params = 
      URI.encode_query(%{
        grant_type: "authorization_code",  # Authorization Code Grant 방식 명시
        code: code                         # 인증 서버에서 받은 code
      })

    # HTTP Basic 인증 헤더 생성 (RFC 6749 표준)
    auth_header = create_basic_auth_header(client_id, client_secret)
    headers = [{"Authorization", auth_header}]

    # GET 요청으로 토큰 요청 (밴드 API 명세에 따름)
    case HTTPoison.get("#{url}?#{params}", headers) do
      # 성공 응답 (200 OK)
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, token_data} -> {:ok, token_data}
          {:error, _} -> {:error, :invalid_response}
        end
      
      # HTTP 에러 응답 (4xx, 5xx)
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        case Jason.decode(body) do
          {:ok, error_data} -> {:error, {status_code, error_data}}
          {:error, _} -> {:error, {status_code, :invalid_response}}
        end
      
      # 네트워크 에러 (연결 실패, 타임아웃 등)
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Refresh token을 사용하여 새로운 access token 발급
  
  Access token이 만료되었을 때 refresh token을 사용하여
  새로운 access token을 발급받습니다. 사용자의 재로그인 없이
  토큰을 갱신할 수 있어 사용자 경험을 향상시킵니다.
  
  ## Parameters
  - `client_id`: 클라이언트 ID
  - `client_secret`: 클라이언트 시크릿
  - `refresh_token`: 이전에 발급받은 refresh token
  
  ## Returns
  - `{:ok, token_data}`: 성공 시 새로운 토큰 정보
  - `{:error, {status_code, error_data}}`: HTTP 에러
  - `{:error, :invalid_response}`: JSON 파싱 실패
  - `{:error, error}`: 네트워크 에러
  
  ## Notes
  - Refresh token도 만료될 수 있으므로 에러 시 재로그인 유도 필요
  - 새로 발급받은 토큰으로 기존 토큰을 교체해야 함
  """
  def refresh_token(client_id, client_secret, refresh_token) do
    base_url = Application.get_env(:band_accounts, :auth_base_url, @auth_base_url)
    url = "#{base_url}/oauth2/token"
    
    # Refresh Token Grant 요청 파라미터
    params = 
      URI.encode_query(%{
        grant_type: "refresh_token",      # Refresh Token Grant 방식
        refresh_token: refresh_token      # 기존 refresh token
      })

    auth_header = create_basic_auth_header(client_id, client_secret)
    headers = [{"Authorization", auth_header}]

    # 토큰 갱신 요청 처리 (get_access_token과 동일한 로직)
    case HTTPoison.get("#{url}?#{params}", headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, token_data} -> {:ok, token_data}
          {:error, _} -> {:error, :invalid_response}
        end
      
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        case Jason.decode(body) do
          {:ok, error_data} -> {:error, {status_code, error_data}}
          {:error, _} -> {:error, {status_code, :invalid_response}}
        end
      
      {:error, error} ->
        {:error, error}
    end
  end

  @doc false
  # HTTP Basic 인증 헤더 생성
  # 
  # RFC 6749 (OAuth 2.0)와 RFC 7617 (HTTP Basic Authentication)에 따라
  # client_id:client_secret 형태의 문자열을 Base64로 인코딩하여
  # "Basic <encoded_credentials>" 형태의 헤더를 생성합니다.
  #
  # ## Parameters
  # - `client_id`: 클라이언트 ID
  # - `client_secret`: 클라이언트 시크릿
  #
  # ## Returns
  # "Basic <base64_encoded_credentials>" 형태의 인증 헤더 문자열
  defp create_basic_auth_header(client_id, client_secret) do
    # RFC 6749 Section 2.3.1에 따른 클라이언트 인증
    credentials = "#{client_id}:#{client_secret}"
    encoded = Base.encode64(credentials)
    "Basic #{encoded}"
  end
end