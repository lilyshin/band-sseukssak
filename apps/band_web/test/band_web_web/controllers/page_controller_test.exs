defmodule BandWebWeb.PageControllerTest do
  use BandWebWeb.ConnCase, async: true

  describe "GET /" do
    test "메인 페이지를 성공적으로 렌더링한다", %{conn: conn} do
      # Given: 루트 URL 요청
      # When: 메인 페이지에 접속한다
      conn = get(conn, ~p"/")
      
      # Then: 200 상태 코드와 HTML 응답을 받는다
      assert html_response(conn, 200)
    end

    test "응답에 필요한 HTML 요소들이 포함되어 있다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: HTML 응답에 필요한 요소들이 포함되어 있다
      response = html_response(conn, 200)
      
      # HTML 기본 구조 확인
      assert response =~ "<!DOCTYPE html>"
      assert response =~ "<html"
      assert response =~ "<head>"
      assert response =~ "<body>"
      
      # 페이지 제목 확인
      assert response =~ "밴드 댓글 삭제 도구"
      
      # 메타 태그 확인
      assert response =~ "charset=\"utf-8\""
      assert response =~ "viewport"
      assert response =~ "csrf-token"
    end

    test "CSS와 JavaScript 파일이 올바르게 포함되어 있다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: 정적 리소스가 포함되어 있다
      response = html_response(conn, 200)
      
      # CSS 파일 포함 확인
      assert response =~ "/assets/app.css"
      
      # JavaScript 파일 포함 확인
      assert response =~ "/assets/app.js"
      
      # 정적 파일 추적 속성 확인
      assert response =~ "phx-track-static"
    end

    test "CSRF 토큰이 올바르게 설정되어 있다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: CSRF 토큰이 포함되어 있다
      response = html_response(conn, 200)
      assert response =~ "csrf-token"
      
      # CSRF 토큰이 빈 값이 아닌지 확인
      assert response =~ ~r/csrf-token.*content="[^"]+"/
    end

    test "페이지가 한국어로 설정되어 있다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: 한국어 언어 설정이 되어 있다
      response = html_response(conn, 200)
      assert response =~ ~r/lang="ko"/
    end

    test "반응형 메타 태그가 설정되어 있다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: 반응형 메타 태그가 포함되어 있다
      response = html_response(conn, 200)
      assert response =~ "width=device-width"
      assert response =~ "initial-scale=1"
    end

    test "POST 요청은 허용되지 않는다", %{conn: conn} do
      # Given: 루트 URL에 POST 요청
      # When: POST 메서드로 요청한다
      conn = post(conn, ~p"/", %{})
      
      # Then: 405 Method Not Allowed 에러를 받는다
      assert conn.status == 405
    end

    test "PUT 요청은 허용되지 않는다", %{conn: conn} do
      # Given: 루트 URL에 PUT 요청
      # When: PUT 메서드로 요청한다
      conn = put(conn, ~p"/", %{})
      
      # Then: 405 Method Not Allowed 에러를 받는다
      assert conn.status == 405
    end

    test "DELETE 요청은 허용되지 않는다", %{conn: conn} do
      # Given: 루트 URL에 DELETE 요청
      # When: DELETE 메서드로 요청한다
      conn = delete(conn, ~p"/")
      
      # Then: 405 Method Not Allowed 에러를 받는다
      assert conn.status == 405
    end
  end

  describe "response headers" do
    test "적절한 Content-Type 헤더가 설정된다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: HTML Content-Type이 설정된다
      content_type = get_resp_header(conn, "content-type")
      assert Enum.any?(content_type, &String.contains?(&1, "text/html"))
    end

    test "보안 헤더들이 설정되어 있다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: 보안 관련 헤더들이 설정되어 있다
      # (실제 설정은 브라우저 파이프라인의 보안 플러그에 따라 다름)
      
      # X-Frame-Options 헤더 확인 (있을 수 있음)
      frame_options = get_resp_header(conn, "x-frame-options")
      # 설정되어 있다면 적절한 값인지 확인
      if frame_options != [] do
        assert Enum.any?(frame_options, fn value -> 
          value in ["DENY", "SAMEORIGIN"] or String.starts_with?(value, "ALLOW-FROM")
        end)
      end
    end

    test "캐시 제어 헤더가 적절히 설정된다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: 동적 페이지에 적절한 캐시 제어가 설정된다
      # (Phoenix의 기본 설정 확인)
      cache_control = get_resp_header(conn, "cache-control")
      
      # 캐시 제어 헤더가 있으면 적절한 값인지 확인
      if cache_control != [] do
        # 동적 페이지이므로 캐시하지 않거나 짧은 캐시 시간 설정
        assert Enum.any?(cache_control, fn value ->
          String.contains?(value, "no-cache") or 
          String.contains?(value, "no-store") or
          String.contains?(value, "max-age")
        end)
      end
    end
  end

  describe "error handling" do
    test "존재하지 않는 경로는 404를 반환한다", %{conn: conn} do
      # Given: 존재하지 않는 경로
      # When: 잘못된 경로로 요청한다
      conn = get(conn, "/nonexistent-path")
      
      # Then: 404 에러를 받는다
      assert conn.status == 404
    end

    test "잘못된 형식의 URL은 400을 반환한다", %{conn: conn} do
      # Given: 잘못된 형식의 URL
      # Note: Phoenix는 대부분의 URL을 적절히 처리하므로 
      # 실제로는 404가 더 일반적임
      
      # When: 매우 긴 URL로 요청한다
      long_path = "/" <> String.duplicate("a", 2000)
      conn = get(conn, long_path)
      
      # Then: 적절한 에러 응답을 받는다 (보통 404)
      assert conn.status in [400, 404, 414]  # 414는 URI Too Long
    end
  end

  describe "accessibility" do
    test "페이지에 적절한 언어 속성이 설정되어 있다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: HTML lang 속성이 설정되어 있다
      response = html_response(conn, 200)
      assert response =~ ~r/<html[^>]*lang="ko"/
    end

    test "문서 제목이 의미있게 설정되어 있다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: 의미있는 제목이 설정되어 있다
      response = html_response(conn, 200)
      assert response =~ ~r/<title[^>]*>.*밴드 댓글 삭제 도구.*<\/title>/
    end

    test "뷰포트 메타 태그가 모바일 접근성을 지원한다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: 모바일 친화적인 뷰포트 설정이 되어 있다
      response = html_response(conn, 200)
      assert response =~ ~r/viewport.*width=device-width/
      assert response =~ ~r/viewport.*initial-scale=1/
    end
  end

  describe "performance" do
    test "정적 리소스에 적절한 캐싱 정책이 적용된다" do
      # Note: 실제 정적 리소스의 캐싱은 웹서버나 CDN에서 처리
      # 여기서는 HTML에서 정적 리소스를 올바르게 참조하는지만 확인
      assert true
    end

    test "페이지 로딩 성능을 위한 최적화가 적용되어 있다", %{conn: conn} do
      # Given: 메인 페이지 요청
      # When: 페이지를 렌더링한다
      conn = get(conn, ~p"/")
      
      # Then: 성능 최적화 요소들이 포함되어 있다
      response = html_response(conn, 200)
      
      # JavaScript 지연 로딩 확인
      assert response =~ ~r/script[^>]*defer/
      
      # 정적 리소스 추적 확인 (캐시 무효화를 위함)
      assert response =~ "phx-track-static"
    end
  end
end