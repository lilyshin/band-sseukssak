defmodule BandAccountsTest do
  use ExUnit.Case
  doctest BandAccounts

  describe "delegation functions" do
    test "get_auth_url/2 delegates to OAuth module" do
      # Given: 클라이언트 정보
      client_id = "test_client"
      redirect_uri = "https://example.com/callback"
      
      # When: 메인 모듈을 통해 인증 URL을 생성한다
      auth_url = BandAccounts.get_auth_url(client_id, redirect_uri)
      
      # Then: OAuth 모듈과 동일한 결과를 반환한다
      expected_url = BandAccounts.OAuth.get_auth_url(client_id, redirect_uri)
      assert auth_url == expected_url
    end

    test "get_access_token/3 delegates to OAuth module" do
      # 실제 네트워크 호출을 피하기 위해 간단한 위임 확인만 수행
      # (상세한 테스트는 OAuth 모듈에서 처리)
      assert function_exported?(BandAccounts, :get_access_token, 3)
    end

    test "refresh_token/3 delegates to OAuth module" do
      # 실제 네트워크 호출을 피하기 위해 간단한 위임 확인만 수행
      # (상세한 테스트는 OAuth 모듈에서 처리)
      assert function_exported?(BandAccounts, :refresh_token, 3)
    end
  end
end
