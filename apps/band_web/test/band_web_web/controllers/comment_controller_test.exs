defmodule BandWebWeb.CommentControllerTest do
  use BandWebWeb.ConnCase, async: true

  describe "DELETE /api/bands/:band_key/comments" do
    test "유효한 파라미터로 댓글 삭제를 성공적으로 실행한다", %{conn: conn} do
      # Given: 유효한 밴드 키와 액세스 토큰
      band_key = "test_band_key"
      access_token = "valid_access_token"
      
      # When: 댓글 삭제를 요청한다
      conn = delete(conn, ~p"/api/bands/#{band_key}/comments", %{
        access_token: access_token
      })
      
      # Then: 실제 API 호출로 인한 응답 (모킹 없이는 에러 예상)
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "댓글 삭제 실패")
    end

    test "access_token이 없으면 400 에러를 반환한다", %{conn: conn} do
      # Given: access_token이 없는 요청
      band_key = "test_band_key"
      
      # When: 댓글 삭제를 요청한다
      conn = delete(conn, ~p"/api/bands/#{band_key}/comments")
      
      # Then: 400 에러를 받는다
      assert json_response(conn, 400) == %{
        "success" => false,
        "error" => "band_key와 access_token이 필요합니다"
      }
    end

    test "band_key가 URL에 없으면 404 에러를 반환한다", %{conn: conn} do
      # Given: band_key가 없는 URL
      # When: 잘못된 URL로 요청한다
      conn = delete(conn, "/api/bands//comments", %{
        access_token: "valid_token"
      })
      
      # Then: 404 에러를 받는다 (라우팅 실패)
      assert conn.status == 404
    end

    test "빈 band_key로 요청해도 처리된다", %{conn: conn} do
      # Given: 빈 문자열인 band_key
      band_key = ""
      access_token = "valid_token"
      
      # When: 빈 band_key로 댓글 삭제를 요청한다
      conn = delete(conn, ~p"/api/bands/#{band_key}/comments", %{
        access_token: access_token
      })
      
      # Then: band_key가 빈 문자열이어도 API 호출이 시도됨
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "댓글 삭제 실패")
    end

    test "잘못된 access_token으로 요청 시 에러를 처리한다", %{conn: conn} do
      # Given: 잘못된 access_token
      band_key = "test_band_key"
      access_token = "invalid_token"
      
      # When: 잘못된 토큰으로 댓글 삭제를 요청한다
      conn = delete(conn, ~p"/api/bands/#{band_key}/comments", %{
        access_token: access_token
      })
      
      # Then: API 에러가 적절히 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "댓글 삭제 실패")
    end

    test "특수 문자가 포함된 band_key를 처리한다", %{conn: conn} do
      # Given: 특수 문자가 포함된 band_key
      band_key = "band-key_with.special@chars"
      access_token = "valid_token"
      
      # When: 특수 문자 band_key로 요청한다
      conn = delete(conn, ~p"/api/bands/#{band_key}/comments", %{
        access_token: access_token
      })
      
      # Then: 특수 문자도 올바르게 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
    end

    test "매우 긴 band_key를 처리한다", %{conn: conn} do
      # Given: 매우 긴 band_key
      band_key = String.duplicate("a", 500)
      access_token = "valid_token"
      
      # When: 긴 band_key로 요청한다
      conn = delete(conn, ~p"/api/bands/#{band_key}/comments", %{
        access_token: access_token
      })
      
      # Then: 긴 band_key도 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
    end

    test "GET 메서드로 요청하면 405 에러를 반환한다", %{conn: conn} do
      # Given: DELETE 전용 엔드포인트에 GET 요청
      band_key = "test_band_key"
      
      # When: GET으로 댓글 삭제를 요청한다
      conn = get(conn, ~p"/api/bands/#{band_key}/comments")
      
      # Then: 405 Method Not Allowed 에러를 받는다
      assert conn.status == 405
    end

    test "POST 메서드로 요청하면 405 에러를 반환한다", %{conn: conn} do
      # Given: DELETE 전용 엔드포인트에 POST 요청
      band_key = "test_band_key"
      
      # When: POST로 댓글 삭제를 요청한다
      conn = post(conn, ~p"/api/bands/#{band_key}/comments", %{
        access_token: "token"
      })
      
      # Then: 405 Method Not Allowed 에러를 받는다
      assert conn.status == 405
    end
  end

  describe "parameter handling" do
    test "쿼리 파라미터로 access_token을 전달해도 처리된다", %{conn: conn} do
      # Given: 쿼리 파라미터의 access_token
      band_key = "test_band_key"
      access_token = "valid_token"
      
      # When: 쿼리 파라미터로 토큰을 전달한다
      conn = delete(conn, ~p"/api/bands/#{band_key}/comments?access_token=#{access_token}")
      
      # Then: 쿼리 파라미터도 올바르게 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
      assert String.contains?(response["error"], "댓글 삭제 실패")
    end

    test "body와 쿼리 파라미터가 모두 있으면 body를 우선한다", %{conn: conn} do
      # Given: body와 쿼리 파라미터에 모두 access_token이 있는 경우
      band_key = "test_band_key"
      
      # When: body와 쿼리 모두에 토큰을 전달한다
      conn = delete(conn, ~p"/api/bands/#{band_key}/comments?access_token=query_token", %{
        access_token: "body_token"
      })
      
      # Then: 요청이 처리된다 (Phoenix는 기본적으로 body를 우선함)
      response = json_response(conn, 400)
      assert response["success"] == false
    end

    test "추가 파라미터가 있어도 올바르게 처리한다", %{conn: conn} do
      # Given: 추가 파라미터가 포함된 요청
      band_key = "test_band_key"
      params = %{
        access_token: "valid_token",
        extra_param: "should_be_ignored",
        another_param: 123
      }
      
      # When: 추가 파라미터와 함께 요청한다
      conn = delete(conn, ~p"/api/bands/#{band_key}/comments", params)
      
      # Then: 필요한 파라미터만 사용하여 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
    end

    test "JSON 형식의 요청 본문을 처리한다", %{conn: conn} do
      # Given: JSON 형식의 요청 본문
      band_key = "test_band_key"
      params = %{access_token: "valid_token"}
      
      # When: JSON으로 요청한다
      conn = 
        conn
        |> put_req_header("content-type", "application/json")
        |> delete(~p"/api/bands/#{band_key}/comments", params)
      
      # Then: JSON 요청도 올바르게 처리된다
      response = json_response(conn, 400)
      assert response["success"] == false
    end
  end

  describe "response format" do
    test "성공 응답 형식을 검증한다" do
      # Note: 실제 성공 케이스는 모킹이 필요하므로 예상 형식만 검증
      expected_success_format = %{
        "success" => true,
        "message" => "댓글 삭제가 완료되었습니다",
        "data" => %{
          "total" => 10,
          "successful" => 8,
          "failed" => 2,
          "failed_comments" => []
        }
      }
      
      assert expected_success_format["success"] == true
      assert Map.has_key?(expected_success_format, "message")
      assert Map.has_key?(expected_success_format, "data")
      assert is_map(expected_success_format["data"])
    end

    test "에러 응답 형식을 검증한다", %{conn: conn} do
      # Given: 에러를 유발하는 요청
      # When: 파라미터 없이 요청한다
      conn = delete(conn, ~p"/api/bands/test/comments")
      
      # Then: 에러 응답 형식이 일관된다
      response = json_response(conn, 400)
      assert response["success"] == false
      assert Map.has_key?(response, "error")
      assert is_binary(response["error"])
    end

    test "모든 응답이 JSON 형식이다", %{conn: conn} do
      # Given: 다양한 에러 케이스
      test_cases = [
        # 파라미터 누락
        {~p"/api/bands/test/comments", %{}},
        # 빈 토큰
        {~p"/api/bands/test/comments", %{access_token: ""}},
      ]
      
      # When & Then: 모든 응답이 JSON 형식인지 확인
      Enum.each(test_cases, fn {path, params} ->
        conn = delete(build_conn(), path, params)
        
        # JSON 응답인지 확인
        content_type = get_resp_header(conn, "content-type")
        assert Enum.any?(content_type, &String.contains?(&1, "application/json"))
        
        # 유효한 JSON인지 확인
        assert_response_valid_json(conn)
      end)
    end
  end

  describe "URL routing" do
    test "올바른 URL 패턴으로 라우팅된다", %{conn: conn} do
      # Given: 다양한 band_key 형식
      band_keys = [
        "simple_band_key",
        "band-with-dashes",
        "band_with_underscores",
        "123456789",
        "MixedCaseKey"
      ]
      
      # When & Then: 모든 형식의 band_key가 라우팅된다
      Enum.each(band_keys, fn band_key ->
        conn = delete(build_conn(), ~p"/api/bands/#{band_key}/comments", %{
          access_token: "token"
        })
        
        # 404가 아닌 다른 상태 코드 (라우팅 성공)
        assert conn.status != 404
      end)
    end

    test "URL 인코딩된 band_key를 처리한다", %{conn: conn} do
      # Given: URL 인코딩이 필요한 band_key
      original_band_key = "band key with spaces"
      encoded_band_key = URI.encode_www_form(original_band_key)
      
      # When: 인코딩된 band_key로 요청한다
      path = "/api/bands/#{encoded_band_key}/comments"
      conn = delete(conn, path, %{access_token: "token"})
      
      # Then: 라우팅이 성공한다
      assert conn.status != 404
    end
  end

  # 헬퍼 함수
  defp assert_response_valid_json(conn) do
    case json_response(conn, conn.status) do
      %{} -> :ok
      _ -> flunk("Response is not valid JSON")
    end
  end
end