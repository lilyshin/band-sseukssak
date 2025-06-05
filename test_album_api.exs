# 앨범 API 테스트 스크립트
# 실제 토큰과 밴드 키가 필요합니다

# 테스트용 데이터 (실제 값으로 교체 필요)
access_token = "YOUR_ACCESS_TOKEN_HERE"
band_key = "YOUR_BAND_KEY_HERE"

IO.puts("🧪 앨범 API 테스트 시작...")

# 1. 앨범 목록 조회 테스트
IO.puts("\n📁 앨범 목록 조회 테스트")
case BandCore.API.get_albums(access_token, band_key) do
  {:ok, %{"result_data" => %{"items" => albums}}} ->
    IO.puts("✅ 앨범 목록 조회 성공: #{length(albums)}개 앨범")
    
    # 각 앨범 정보 출력
    Enum.each(albums, fn album ->
      album_key = album["photo_album_key"]
      album_name = album["name"] || "제목 없음"
      photo_count = album["photo_count"] || 0
      author_name = get_in(album, ["author", "name"]) || "작성자 불명"
      
      IO.puts("  📸 앨범: \"#{album_name}\" (#{photo_count}장) by #{author_name}")
      IO.puts("     키: #{album_key}")
      
      # 첫 번째 앨범의 사진 목록도 테스트
      if album == List.first(albums) do
        IO.puts("\n📷 첫 번째 앨범의 사진 목록 조회 테스트")
        case BandCore.API.get_album_photos(access_token, band_key, album_key) do
          {:ok, %{"result_data" => %{"items" => photos}}} ->
            IO.puts("✅ 사진 목록 조회 성공: #{length(photos)}장")
            
            # 각 사진 정보 출력
            Enum.take(photos, 3) |> Enum.each(fn photo ->
              photo_key = photo["photo_key"]
              author_name = get_in(photo, ["author", "name"]) || "작성자 불명"
              comment_count = photo["comment_count"] || 0
              
              IO.puts("  🖼️  사진: #{photo_key} (#{comment_count}개 댓글) by #{author_name}")
              
              # 첫 번째 사진의 댓글도 테스트
              if photo == List.first(photos) do
                IO.puts("\n💬 첫 번째 사진의 댓글 조회 테스트")
                case BandCore.API.get_photo_comments(access_token, band_key, photo_key) do
                  {:ok, %{"result_data" => %{"items" => comments}}} ->
                    IO.puts("✅ 사진 댓글 조회 성공: #{length(comments)}개 댓글")
                    
                    Enum.take(comments, 2) |> Enum.each(fn comment ->
                      comment_key = comment["comment_key"]
                      content = comment["content"] || ""
                      author_name = get_in(comment, ["author", "name"]) || "작성자 불명"
                      clean_content = content |> String.replace(~r/<[^>]*>/, "") |> String.slice(0, 30)
                      
                      IO.puts("    💭 댓글: \"#{clean_content}\" by #{author_name}")
                    end)
                    
                  {:ok, result} ->
                    IO.puts("⚠️  사진 댓글 조회 - 예상과 다른 응답 구조: #{inspect(result)}")
                    
                  {:error, reason} ->
                    IO.puts("❌ 사진 댓글 조회 실패: #{inspect(reason)}")
                end
              end
            end)
            
          {:ok, result} ->
            IO.puts("⚠️  사진 목록 조회 - 예상과 다른 응답 구조: #{inspect(result)}")
            
          {:error, reason} ->
            IO.puts("❌ 사진 목록 조회 실패: #{inspect(reason)}")
        end
      end
    end)
    
  {:ok, result} ->
    IO.puts("⚠️  앨범 목록 조회 - 예상과 다른 응답 구조: #{inspect(result)}")
    
  {:error, reason} ->
    IO.puts("❌ 앨범 목록 조회 실패: #{inspect(reason)}")
end

IO.puts("\n🏁 테스트 완료!")