defmodule BandCore.APITest do
  use ExUnit.Case, async: true
  alias BandCore.API

  setup do
    bypass = Bypass.open()
    
    # API 모듈의 기본 URL을 테스트용 bypass 서버로 변경
    original_url = Application.get_env(:band_core, :api_base_url, "https://openapi.band.us")
    Application.put_env(:band_core, :api_base_url, "http://localhost:#{bypass.port}")
    
    on_exit(fn ->
      Application.put_env(:band_core, :api_base_url, original_url)
    end)
    
    {:ok, bypass: bypass}
  end

  describe "get_profile/2" do
    test "사용자 프로필을 성공적으로 조회한다", %{bypass: bypass} do
      # Given: 성공적인 프로필 응답을 모킹한다
      expected_response = %{
        "result_code" => 1,
        "result_data" => %{
          "user_key" => "test_user_key",
          "profile_image_url" => "http://example.com/image.jpg",
          "name" => "Test User",
          "is_app_member" => true,
          "message_allowed" => true
        }
      }
      
      Bypass.expect_once(bypass, "GET", "/v2/profile", fn conn ->
        # 쿼리 파라미터 검증
        params = Plug.Conn.Query.decode(conn.query_string)
        assert params["access_token"] == "test_token"
        
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(expected_response))
      end)
      
      # When: 프로필을 조회한다
      result = API.get_profile("test_token")
      
      # Then: 성공적으로 프로필을 받는다
      assert {:ok, profile_data} = result
      assert profile_data == expected_response
    end

    test "밴드 키와 함께 프로필을 조회한다", %{bypass: bypass} do
      # Given: 밴드별 프로필 응답을 모킹한다
      expected_response = %{
        "result_code" => 1,
        "result_data" => %{
          "user_key" => "test_user_key",
          "name" => "Test User in Band"
        }
      }
      
      Bypass.expect_once(bypass, "GET", "/v2/profile", fn conn ->
        params = Plug.Conn.Query.decode(conn.query_string)
        assert params["access_token"] == "test_token"
        assert params["band_key"] == "test_band_key"
        
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(expected_response))
      end)
      
      # When: 밴드 키와 함께 프로필을 조회한다
      result = API.get_profile("test_token", "test_band_key")
      
      # Then: 성공적으로 프로필을 받는다
      assert {:ok, profile_data} = result
      assert profile_data == expected_response
    end

    test "잘못된 토큰으로 401 에러를 처리한다", %{bypass: bypass} do
      # Given: 401 에러 응답을 모킹한다
      error_response = %{
        "result_code" => 0,
        "error_message" => "Invalid access token"
      }
      
      Bypass.expect_once(bypass, "GET", "/v2/profile", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(401, Jason.encode!(error_response))
      end)
      
      # When: 잘못된 토큰으로 프로필을 조회한다
      result = API.get_profile("invalid_token")
      
      # Then: 에러를 올바르게 처리한다
      assert {:error, {401, ^error_response}} = result
    end
  end

  describe "get_bands/1" do
    test "사용자의 밴드 목록을 성공적으로 조회한다", %{bypass: bypass} do
      # Given: 밴드 목록 응답을 모킹한다
      expected_response = %{
        "result_code" => 1,
        "result_data" => %{
          "bands" => [
            %{
              "name" => "Test Band 1",
              "band_key" => "band_key_1",
              "cover" => "http://example.com/cover1.jpg",
              "member_count" => 10
            },
            %{
              "name" => "Test Band 2", 
              "band_key" => "band_key_2",
              "cover" => "http://example.com/cover2.jpg",
              "member_count" => 25
            }
          ]
        }
      }
      
      Bypass.expect_once(bypass, "GET", "/v2.1/bands", fn conn ->
        params = Plug.Conn.Query.decode(conn.query_string)
        assert params["access_token"] == "test_token"
        
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(expected_response))
      end)
      
      # When: 밴드 목록을 조회한다
      result = API.get_bands("test_token")
      
      # Then: 성공적으로 밴드 목록을 받는다
      assert {:ok, bands_data} = result
      assert bands_data == expected_response
    end
  end

  describe "get_posts/3" do
    test "밴드의 게시글 목록을 조회한다", %{bypass: bypass} do
      # Given: 게시글 목록 응답을 모킹한다
      expected_response = %{
        "result_code" => 1,
        "result_data" => %{
          "items" => [
            %{
              "post_key" => "post_1",
              "content" => "Test post 1",
              "created_at" => 1609459200000
            }
          ],
          "paging" => %{
            "next_params" => nil
          }
        }
      }
      
      Bypass.expect_once(bypass, "GET", "/v2/band/posts", fn conn ->
        params = Plug.Conn.Query.decode(conn.query_string)
        assert params["access_token"] == "test_token"
        assert params["band_key"] == "test_band_key"
        
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(expected_response))
      end)
      
      # When: 게시글 목록을 조회한다
      result = API.get_posts("test_token", "test_band_key")
      
      # Then: 성공적으로 게시글 목록을 받는다
      assert {:ok, posts_data} = result
      assert posts_data == expected_response
    end

    test "페이징 옵션과 함께 게시글을 조회한다", %{bypass: bypass} do
      # Given: 페이징 파라미터를 포함한 요청을 모킹한다
      Bypass.expect_once(bypass, "GET", "/v2/band/posts", fn conn ->
        params = Plug.Conn.Query.decode(conn.query_string)
        assert params["access_token"] == "test_token"
        assert params["band_key"] == "test_band_key"
        assert params["after"] == "some_after_value"
        assert params["limit"] == "10"
        
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"result_code" => 1, "result_data" => %{}}))
      end)
      
      # When: 페이징 옵션과 함께 게시글을 조회한다
      opts = [after: "some_after_value", limit: "10"]
      result = API.get_posts("test_token", "test_band_key", opts)
      
      # Then: 요청이 성공한다
      assert {:ok, _} = result
    end
  end

  describe "get_comments/4" do
    test "게시글의 댓글 목록을 조회한다", %{bypass: bypass} do
      # Given: 댓글 목록 응답을 모킹한다
      expected_response = %{
        "result_code" => 1,
        "result_data" => %{
          "items" => [
            %{
              "comment_key" => "comment_1",
              "content" => "Test comment",
              "created_at" => 1609459200000,
              "author" => %{
                "name" => "Test User",
                "user_key" => "user_1"
              }
            }
          ],
          "paging" => %{
            "next_params" => nil
          }
        }
      }
      
      Bypass.expect_once(bypass, "GET", "/v2/band/post/comments", fn conn ->
        params = Plug.Conn.Query.decode(conn.query_string)
        assert params["access_token"] == "test_token"
        assert params["band_key"] == "test_band_key"
        assert params["post_key"] == "test_post_key"
        
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(expected_response))
      end)
      
      # When: 댓글 목록을 조회한다
      result = API.get_comments("test_token", "test_band_key", "test_post_key")
      
      # Then: 성공적으로 댓글 목록을 받는다
      assert {:ok, comments_data} = result
      assert comments_data == expected_response
    end
  end

  describe "delete_comment/4" do
    test "댓글을 성공적으로 삭제한다", %{bypass: bypass} do
      # Given: 성공적인 삭제 응답을 모킹한다
      expected_response = %{
        "result_code" => 1,
        "result_data" => %{
          "message" => "success"
        }
      }
      
      Bypass.expect_once(bypass, "POST", "/v2/band/post/comment/remove", fn conn ->
        # POST 요청 body 파싱
        {:ok, body, _} = Plug.Conn.read_body(conn)
        params = Plug.Conn.Query.decode(body)
        
        assert params["access_token"] == "test_token"
        assert params["band_key"] == "test_band_key"
        assert params["post_key"] == "test_post_key"
        assert params["comment_key"] == "test_comment_key"
        
        # Content-Type 헤더 확인
        content_type = Enum.find_value(conn.req_headers, fn
          {"content-type", value} -> value
          _ -> nil
        end)
        assert content_type == "application/x-www-form-urlencoded"
        
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(expected_response))
      end)
      
      # When: 댓글을 삭제한다
      result = API.delete_comment("test_token", "test_band_key", "test_post_key", "test_comment_key")
      
      # Then: 성공적으로 삭제된다
      assert {:ok, delete_data} = result
      assert delete_data == expected_response
    end

    test "권한이 없는 댓글 삭제 시 403 에러를 처리한다", %{bypass: bypass} do
      # Given: 403 에러 응답을 모킹한다
      error_response = %{
        "result_code" => 0,
        "error_message" => "No permission to delete this comment"
      }
      
      Bypass.expect_once(bypass, "POST", "/v2/band/post/comment/remove", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(403, Jason.encode!(error_response))
      end)
      
      # When: 권한이 없는 댓글을 삭제하려고 한다
      result = API.delete_comment("test_token", "test_band_key", "test_post_key", "other_user_comment")
      
      # Then: 에러를 올바르게 처리한다
      assert {:error, {403, ^error_response}} = result
    end
  end

  describe "error handling" do
    test "잘못된 JSON 응답을 처리한다", %{bypass: bypass} do
      # Given: 잘못된 JSON 응답을 모킹한다
      Bypass.expect_once(bypass, "GET", "/v2/profile", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, "invalid json")
      end)
      
      # When: API를 호출한다
      result = API.get_profile("test_token")
      
      # Then: JSON 파싱 에러를 처리한다
      assert {:error, :invalid_response} = result
    end

    test "네트워크 에러를 처리한다" do
      # Given: 존재하지 않는 서버 설정
      Application.put_env(:band_core, :api_base_url, "http://localhost:9999")
      
      # When: API를 호출한다
      result = API.get_profile("test_token")
      
      # Then: 네트워크 에러를 처리한다
      assert {:error, _reason} = result
    end

    test "result_code가 1이 아닌 경우를 에러로 처리한다", %{bypass: bypass} do
      # Given: result_code가 0인 응답을 모킹한다
      error_response = %{
        "result_code" => 0,
        "error_message" => "Some API error"
      }
      
      Bypass.expect_once(bypass, "GET", "/v2/profile", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(error_response))
      end)
      
      # When: API를 호출한다
      result = API.get_profile("test_token")
      
      # Then: API 에러를 처리한다
      assert {:error, ^error_response} = result
    end
  end
end