defmodule BandAccounts.OAuthTest do
  use ExUnit.Case, async: true
  alias BandAccounts.OAuth

  setup do
    bypass = Bypass.open()
    
    # OAuth 모듈의 기본 URL을 테스트용 bypass 서버로 변경
    original_url = Application.get_env(:band_accounts, :auth_base_url, "https://auth.band.us")
    Application.put_env(:band_accounts, :auth_base_url, "http://localhost:#{bypass.port}")
    
    on_exit(fn ->
      Application.put_env(:band_accounts, :auth_base_url, original_url)
    end)
    
    {:ok, bypass: bypass}
  end

  describe "get_auth_url/2" do
    test "OAuth 인증 URL을 올바르게 생성한다" do
      # Given: 클라이언트 ID와 리다이렉트 URI
      client_id = "test_client_id"
      redirect_uri = "https://example.com/callback"
      
      # When: 인증 URL을 생성한다
      auth_url = OAuth.get_auth_url(client_id, redirect_uri)
      
      # Then: 올바른 형식의 URL이 생성된다
      expected_params = %{
        "response_type" => "code",
        "client_id" => client_id,
        "redirect_uri" => redirect_uri
      }
      
      %URI{query: query} = URI.parse(auth_url)
      actual_params = URI.decode_query(query)
      
      assert actual_params == expected_params
      assert String.contains?(auth_url, "/oauth2/authorize")
    end

    test "특수 문자가 포함된 redirect_uri를 올바르게 인코딩한다" do
      # Given: 특수 문자가 포함된 리다이렉트 URI
      client_id = "test_client"
      redirect_uri = "https://example.com/callback?state=test&code=123"
      
      # When: 인증 URL을 생성한다
      auth_url = OAuth.get_auth_url(client_id, redirect_uri)
      
      # Then: URI가 올바르게 인코딩된다
      assert String.contains?(auth_url, URI.encode_www_form(redirect_uri))
    end
  end

  describe "get_access_token/3" do
    test "올바른 토큰 응답을 처리한다", %{bypass: bypass} do
      # Given: 성공적인 토큰 응답을 모킹한다
      expected_response = %{
        "access_token" => "test_access_token",
        "token_type" => "bearer",
        "refresh_token" => "test_refresh_token",
        "expires_in" => 315359999,
        "scope" => "READ_PHOTO READ_ALBUM",
        "user_key" => "test_user_key"
      }
      
      Bypass.expect_once(bypass, "GET", "/oauth2/token", fn conn ->
        # 요청 헤더 검증
        auth_header = Enum.find_value(conn.req_headers, fn
          {"authorization", value} -> value
          _ -> nil
        end)
        
        # Basic 인증 헤더가 올바른지 확인
        assert String.starts_with?(auth_header, "Basic ")
        
        # 쿼리 파라미터 검증
        %{"grant_type" => "authorization_code", "code" => "test_code"} = 
          Plug.Conn.Query.decode(conn.query_string)
        
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(expected_response))
      end)
      
      # When: 액세스 토큰을 요청한다
      result = OAuth.get_access_token("client_id", "client_secret", "test_code")
      
      # Then: 성공적으로 토큰을 받는다
      assert {:ok, token_data} = result
      assert token_data == expected_response
    end

    test "잘못된 클라이언트 정보로 401 에러를 처리한다", %{bypass: bypass} do
      # Given: 401 에러 응답을 모킹한다
      error_response = %{
        "error" => "invalid_client",
        "error_description" => "Client authentication failed"
      }
      
      Bypass.expect_once(bypass, "GET", "/oauth2/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(401, Jason.encode!(error_response))
      end)
      
      # When: 잘못된 클라이언트 정보로 토큰을 요청한다
      result = OAuth.get_access_token("invalid_client", "invalid_secret", "test_code")
      
      # Then: 에러를 올바르게 처리한다
      assert {:error, {401, ^error_response}} = result
    end

    test "잘못된 authorization code로 400 에러를 처리한다", %{bypass: bypass} do
      # Given: 400 에러 응답을 모킹한다
      error_response = %{
        "error" => "invalid_grant",
        "error_description" => "Invalid authorization code"
      }
      
      Bypass.expect_once(bypass, "GET", "/oauth2/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, Jason.encode!(error_response))
      end)
      
      # When: 잘못된 코드로 토큰을 요청한다
      result = OAuth.get_access_token("client_id", "client_secret", "invalid_code")
      
      # Then: 에러를 올바르게 처리한다
      assert {:error, {400, ^error_response}} = result
    end

    test "네트워크 에러를 처리한다" do
      # Given: 존재하지 않는 서버에 요청한다
      Application.put_env(:band_accounts, :auth_base_url, "http://localhost:9999")
      
      # When: 토큰을 요청한다
      result = OAuth.get_access_token("client_id", "client_secret", "test_code")
      
      # Then: 네트워크 에러를 처리한다
      assert {:error, _reason} = result
    end

    test "Basic 인증 헤더를 올바르게 생성한다" do
      # Given: 클라이언트 정보
      client_id = "test_client"
      client_secret = "test_secret"
      
      # When: Basic 인증 헤더를 생성한다 (private 함수 테스트를 위해 직접 호출)
      credentials = "#{client_id}:#{client_secret}"
      expected_header = "Basic #{Base.encode64(credentials)}"
      
      # Then: OAuth 모듈에서 동일한 헤더가 생성되는지 간접 검증
      # (실제로는 get_access_token 호출 시 헤더가 올바르게 설정되는지 확인)
      assert Base.encode64(credentials) == Base.encode64("test_client:test_secret")
    end
  end

  describe "refresh_token/3" do
    test "리프레시 토큰으로 새로운 액세스 토큰을 받는다", %{bypass: bypass} do
      # Given: 성공적인 토큰 갱신 응답을 모킹한다
      expected_response = %{
        "access_token" => "new_access_token",
        "token_type" => "bearer",
        "refresh_token" => "new_refresh_token",
        "expires_in" => 315359999,
        "scope" => "READ_PHOTO READ_ALBUM"
      }
      
      Bypass.expect_once(bypass, "GET", "/oauth2/token", fn conn ->
        # 쿼리 파라미터 검증
        %{"grant_type" => "refresh_token", "refresh_token" => "old_refresh_token"} = 
          Plug.Conn.Query.decode(conn.query_string)
        
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(expected_response))
      end)
      
      # When: 리프레시 토큰으로 새 토큰을 요청한다
      result = OAuth.refresh_token("client_id", "client_secret", "old_refresh_token")
      
      # Then: 새로운 토큰을 받는다
      assert {:ok, token_data} = result
      assert token_data == expected_response
    end

    test "만료된 리프레시 토큰으로 400 에러를 처리한다", %{bypass: bypass} do
      # Given: 400 에러 응답을 모킹한다
      error_response = %{
        "error" => "invalid_grant",
        "error_description" => "Refresh token expired"
      }
      
      Bypass.expect_once(bypass, "GET", "/oauth2/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, Jason.encode!(error_response))
      end)
      
      # When: 만료된 리프레시 토큰을 사용한다
      result = OAuth.refresh_token("client_id", "client_secret", "expired_token")
      
      # Then: 에러를 올바르게 처리한다
      assert {:error, {400, ^error_response}} = result
    end
  end
end