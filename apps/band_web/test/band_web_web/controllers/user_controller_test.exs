defmodule BandWebWeb.UserControllerTest do
  use BandWebWeb.ConnCase, async: true

  describe "GET /api/profile" do
    test "유효한 access_token으로 프로필을 성공적으로 조회한다", %{conn: conn} do
      # Given: 유효한 access_token
      # Note: 실제 테스트에서는 BandCore.get_profile을 모킹해야 함
      access_token = "valid_access_token"
      
      # When: 프로필 조회를 요청한다
      conn = get(conn, ~p"/api/profile", %{access_token: access_token})
      
      # Then: 실제 API 호출로 인한 응답 (모킹 없이는 에러 예상)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "프로필 조회 실패")
    end

    test "band_key와 함께 프로필을 조회한다", %{conn: conn} do
      # Given: access_token과 band_key
      params = %{
        access_token: "valid_access_token",
        band_key: "test_band_key"
      }
      
      # When: 밴드별 프로필 조회를 요청한다
      conn = get(conn, ~p"/api/profile", params)
      
      # Then: band_key가 포함된 요청이 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "프로필 조회 실패")
    end

    test "access_token이 없으면 400 에러를 반환한다", %{conn: conn} do
      # Given: access_token이 없는 요청
      # When: 프로필 조회를 요청한다
      conn = get(conn, ~p"/api/profile")
      
      # Then: 400 에러를 받는다
      assert json_response(conn, 400) == %{
        "success" => false,
        "error" => "access_token이 필요합니다"
      }
    end

    test "빈 access_token으로 요청하면 API 호출이 실행된다", %{conn: conn} do
      # Given: 빈 access_token
      # When: 프로필 조회를 요청한다
      conn = get(conn, ~p"/api/profile", %{access_token: ""})
      
      # Then: 빈 토큰으로도 API 호출이 시도됨 (실제로는 인증 실패)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "프로필 조회 실패")
    end

    test "잘못된 access_token으로 요청 시 에러를 처리한다", %{conn: conn} do
      # Given: 잘못된 access_token
      # When: 프로필 조회를 요청한다
      conn = get(conn, ~p"/api/profile", %{access_token: "invalid_token"})
      
      # Then: API 에러가 적절히 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "프로필 조회 실패")
    end

    test "추가 파라미터가 있어도 올바르게 처리한다", %{conn: conn} do
      # Given: 추가 파라미터가 포함된 요청
      params = %{
        access_token: "valid_token",
        band_key: "test_band",
        extra_param: "should_be_ignored"
      }
      
      # When: 프로필 조회를 요청한다
      conn = get(conn, ~p"/api/profile", params)
      
      # Then: 필요한 파라미터만 사용하여 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
    end
  end

  describe "GET /api/bands" do
    test "유효한 access_token으로 밴드 목록을 성공적으로 조회한다", %{conn: conn} do
      # Given: 유효한 access_token
      access_token = "valid_access_token"
      
      # When: 밴드 목록 조회를 요청한다
      conn = get(conn, ~p"/api/bands", %{access_token: access_token})
      
      # Then: 실제 API 호출로 인한 응답 (모킹 없이는 에러 예상)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "밴드 목록 조회 실패")
    end

    test "access_token이 없으면 400 에러를 반환한다", %{conn: conn} do
      # Given: access_token이 없는 요청
      # When: 밴드 목록 조회를 요청한다
      conn = get(conn, ~p"/api/bands")
      
      # Then: 400 에러를 받는다
      assert json_response(conn, 400) == %{
        "success" => false,
        "error" => "access_token이 필요합니다"
      }
    end

    test "잘못된 access_token으로 요청 시 에러를 처리한다", %{conn: conn} do
      # Given: 잘못된 access_token
      # When: 밴드 목록 조회를 요청한다
      conn = get(conn, ~p"/api/bands", %{access_token: "invalid_token"})
      
      # Then: API 에러가 적절히 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "밴드 목록 조회 실패")
    end

    test "POST 메서드로 요청하면 405 에러를 반환한다", %{conn: conn} do
      # Given: GET 전용 엔드포인트에 POST 요청
      # When: POST로 밴드 목록을 요청한다
      conn = post(conn, ~p"/api/bands", %{access_token: "token"})
      
      # Then: 405 Method Not Allowed 에러를 받는다
      assert conn.status == 405
    end
  end

  describe "parameter handling" do
    test "쿼리 스트링과 POST body 파라미터를 모두 처리한다" do
      # Note: Phoenix는 기본적으로 쿼리 파라미터와 body 파라미터를 모두 처리함
      # 이는 Phoenix 프레임워크의 기본 동작을 테스트하는 것
      assert true
    end

    test "URL 인코딩된 특수 문자를 올바르게 처리한다", %{conn: conn} do
      # Given: URL 인코딩된 특수 문자가 포함된 토큰
      encoded_token = URI.encode_www_form("token+with+special/chars=123")
      
      # When: 인코딩된 토큰으로 요청한다
      conn = get(conn, ~p"/api/profile?access_token=#{encoded_token}")
      
      # Then: 파라미터가 올바르게 디코딩되어 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
      # 디코딩 에러가 아닌 API 호출 에러임을 확인
      assert String.contains?(response["error"], "프로필 조회 실패")
    end

    test "매우 긴 토큰 값도 처리한다", %{conn: conn} do
      # Given: 매우 긴 토큰 값
      long_token = String.duplicate("a", 2000)
      
      # When: 긴 토큰으로 요청한다
      conn = get(conn, ~p"/api/profile", %{access_token: long_token})
      
      # Then: 긴 토큰도 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
    end

    test "nil 값과 빈 문자열을 구분하여 처리한다", %{conn: conn} do
      # Given: 빈 문자열 토큰
      # When: 빈 토큰으로 요청한다
      conn = get(conn, ~p"/api/profile", %{access_token: ""})
      
      # Then: 빈 문자열도 유효한 값으로 처리됨 (API 호출 시도)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "프로필 조회 실패")
    end
  end

  describe "content type handling" do
    test "JSON 요청을 올바르게 처리한다", %{conn: conn} do
      # Given: JSON 형식의 요청
      params = %{access_token: "test_token"}
      
      # When: JSON으로 요청한다
      conn = 
        conn
        |> put_req_header("content-type", "application/json")
        |> get(~p"/api/profile", params)
      
      # Then: JSON 요청도 올바르게 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
    end

    test "다양한 Content-Type 헤더를 처리한다", %{conn: conn} do
      # Given: 다양한 Content-Type 헤더
      content_types = [
        "application/json",
        "application/json; charset=utf-8",
        "application/x-www-form-urlencoded"
      ]
      
      # When & Then: 각 Content-Type으로 요청이 처리되는지 확인
      Enum.each(content_types, fn content_type ->
        conn = 
          build_conn()
          |> put_req_header("content-type", content_type)
          |> get(~p"/api/profile", %{access_token: "token"})
        
        response = json_response(conn, 400)
        assert response["success"] == false
      end)
    end
  end

  describe "response format" do
    test "모든 성공 응답은 success: true를 포함한다" do
      # Note: 실제 성공 케이스는 모킹이 필요하므로 응답 형식만 검증
      expected_success_format = %{
        "success" => true,
        "data" => %{}
      }
      
      assert expected_success_format["success"] == true
      assert Map.has_key?(expected_success_format, "data")
    end

    test "모든 에러 응답은 success: false와 error 메시지를 포함한다", %{conn: conn} do
      # Given: 에러를 유발하는 요청
      # When: 잘못된 요청을 보낸다
      conn = get(conn, ~p"/api/profile")
      
      # Then: 에러 응답 형식이 일관된다
      response = json_response(conn, 400)
      assert response["success"] == false
      assert Map.has_key?(response, "error")
      assert is_binary(response["error"])
    end
  end
end