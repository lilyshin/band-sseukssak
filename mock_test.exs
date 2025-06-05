# Mock 데이터로 앨범 API 구조 테스트

# Mock 앨범 데이터 (Band API 문서 예시)
mock_albums = %{
  "result_code" => 1,
  "result_data" => %{
    "paging" => %{
      "previous_params" => nil,
      "next_params" => %{
        "after" => "AABWu8gnqZaHTsKDa4zVn7hK",
        "band_key" => "xxxx"
      }
    },
    "items" => [
      %{
        "name" => "Flower Album",
        "photo_album_key" => "AAA4EPU-k8RKboHPybmZaUw5",
        "photo_count" => 1,
        "author" => %{  # API 문서에서는 "owner"이지만 일부 응답에서는 "author"일 수 있음
          "name" => "Charley",
          "description" => "ㅋㅋ",
          "profile_image_url" => "http://band.phinf.campmobile.net/20130719_224/xxx/test.jpg"
        },
        "created_at" => 1443778960000
      },
      %{
        "name" => "Europe Tour",
        "photo_album_key" => "AABWu8gnqZaHTsKDa4zVn7hK",
        "photo_count" => 3,
        "owner" => %{  # API 문서에 따른 정확한 필드명
          "name" => "Jordan Lee",
          "description" => "This is description.",
          "profile_image_url" => "http://band.phinf.campmobile.net/20130719_224/xxxx/test.jpg"
        },
        "created_at" => 1443691414000
      }
    ],
    "total_photo_count" => 10
  }
}

# Mock 사진 데이터
mock_photos = %{
  "result_code" => 1,
  "result_data" => %{
    "paging" => %{
      "previous_params" => nil,
      "next_params" => %{
        "after" => "294038803",
        "photo_album_key" => "wdfdf929",
        "band_key" => "dhjd8djd7"
      }
    },
    "items" => [
      %{
        "width" => 1280,
        "height" => 720,
        "photo_key" => "AACEdJ3oAh0ICHh98X5so5aI",
        "photo_album_key" => "AADgiaZXYFi1lV-JpylzUvwO",
        "author" => %{
          "name" => "Jordan Lee",
          "description" => "This is description.",
          "profile_image_url" => "http://band.phinf.campmobile.net/20130719_224/xxx/test.jpg"
        },
        "url" => "http://beta.coresos.phinf.naver.net/a/xxxx/test.jpg",
        "created_at" => 1443691385000,
        "comment_count" => 1,
        "emotion_count" => 1,
        "is_video_thumbnail" => false
      }
    ]
  }
}

IO.puts("🧪 Mock 데이터로 앨범 처리 로직 테스트")

# 앨범 처리 테스트
case mock_albums do
  %{"result_data" => %{"items" => albums}} ->
    IO.puts("✅ 앨범 목록 파싱 성공: #{length(albums)}개 앨범")
    
    Enum.each(albums, fn album ->
      album_key = album["photo_album_key"]
      album_name = album["name"] || "제목 없음"
      photo_count = album["photo_count"] || 0
      
      # 작성자 필드 처리 (author 또는 owner)
      author_name = get_in(album, ["author", "name"]) || get_in(album, ["owner", "name"]) || "작성자 불명"
      
      IO.puts("  📸 앨범: \"#{album_name}\" (#{photo_count}장) by #{author_name}")
      IO.puts("     키: #{album_key}")
    end)
    
  _ ->
    IO.puts("❌ 앨범 목록 파싱 실패")
end

# 사진 처리 테스트
IO.puts("\n📷 사진 목록 처리 테스트")
case mock_photos do
  %{"result_data" => %{"items" => photos}} ->
    IO.puts("✅ 사진 목록 파싱 성공: #{length(photos)}장")
    
    Enum.each(photos, fn photo ->
      photo_key = photo["photo_key"]
      author_name = get_in(photo, ["author", "name"]) || "작성자 불명"
      comment_count = photo["comment_count"] || 0
      
      IO.puts("  🖼️  사진: #{photo_key} (#{comment_count}개 댓글) by #{author_name}")
      
      # 사진을 post_key로 사용하는 댓글 조회 시뮬레이션
      IO.puts("     → 댓글 조회용 post_key: #{photo_key}")
    end)
    
  _ ->
    IO.puts("❌ 사진 목록 파싱 실패")
end

IO.puts("\n✨ Mock 테스트 완료! API 구조가 올바르게 처리되고 있습니다.")