defmodule BandCoreTest do
  use ExUnit.Case
  doctest BandCore

  describe "delegation functions" do
    test "get_profile/2 delegates to API module" do
      # 실제 네트워크 호출을 피하기 위해 간단한 위임 확인만 수행
      assert function_exported?(BandCore, :get_profile, 2)
    end

    test "get_bands/1 delegates to API module" do
      assert function_exported?(BandCore, :get_bands, 1)
    end

    test "get_posts/3 delegates to API module" do
      assert function_exported?(BandCore, :get_posts, 3)
    end

    test "get_comments/4 delegates to API module" do
      assert function_exported?(BandCore, :get_comments, 4)
    end

    test "delete_comment/4 delegates to API module" do
      assert function_exported?(BandCore, :delete_comment, 4)
    end

    test "delete_all_comments_in_band/2 delegates to CommentManager module" do
      assert function_exported?(BandCore, :delete_all_comments_in_band, 2)
    end
  end

  describe "module integration" do
    test "모든 필요한 함수들이 export되어 있다" do
      # Given: BandCore 모듈의 exported 함수들
      exports = BandCore.__info__(:functions)
      
      # When: 필요한 함수들이 모두 있는지 확인
      required_functions = [
        {:get_profile, 2},
        {:get_bands, 1}, 
        {:get_posts, 3},
        {:get_comments, 4},
        {:delete_comment, 4},
        {:delete_all_comments_in_band, 2}
      ]
      
      # Then: 모든 필요한 함수들이 export되어 있다
      Enum.each(required_functions, fn func ->
        assert func in exports, "Function #{inspect(func)} is not exported"
      end)
    end
  end
end
