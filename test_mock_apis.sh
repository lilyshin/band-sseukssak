#!/bin/bash

echo "🧪 Band API 구조 테스트 - Mock 응답으로 확인"
echo "=================================="

echo ""
echo "📁 1. 앨범 목록 API 응답 구조 테스트"
echo "GET https://openapi.band.us/v2/band/albums"
echo ""

# Mock 앨범 응답 (API 문서 예시)
cat << 'EOF'
{
    "result_code": 1,
    "result_data": {
        "paging": {
            "previous_params": null,
            "next_params": {
                "after": "AABWu8gnqZaHTsKDa4zVn7hK",
                "band_key": "xxxx"
            }
        },
        "items": [
            {
                "name": "Flower Album",
                "photo_album_key": "AAA4EPU-k8RKboHPybmZaUw5",
                "photo_count": 1,
                "owner": {
                    "name": "Charley",
                    "description": "ㅋㅋ",
                    "profile_image_url": "http://band.phinf.campmobile.net/20130719_224/xxx/test.jpg"
                },
                "created_at": 1443778960000
            },
            {
                "name": "Europe Tour",
                "photo_album_key": "AABWu8gnqZaHTsKDa4zVn7hK",
                "photo_count": 3,
                "owner": {
                    "name": "Jordan Lee",
                    "description": "This is description.",
                    "profile_image_url": "http://band.phinf.campmobile.net/20130719_224/xxxx/test.jpg"
                },
                "created_at": 1443691414000
            }
        ],
        "total_photo_count": 10
    }
}
EOF

echo ""
echo "📷 2. 사진 목록 API 응답 구조 테스트"
echo "GET https://openapi.band.us/v2/band/album/photos"
echo ""

# Mock 사진 응답
cat << 'EOF'
{
    "result_code": 1,
    "result_data": {
        "paging": {
            "previous_params": null,
            "next_params": {
                "after": "294038803",
                "photo_album_key": "wdfdf929", 
                "band_key": "dhjd8djd7"
            }
        },
        "items": [
            {
                "width": 1280,
                "height": 720,
                "photo_key": "AACEdJ3oAh0ICHh98X5so5aI",
                "photo_album_key": "AADgiaZXYFi1lV-JpylzUvwO",
                "author": {
                    "name": "Jordan Lee",
                    "description": "This is description.",
                    "profile_image_url": "http://band.phinf.campmobile.net/20130719_224/xxx/test.jpg"
                },
                "url": "http://beta.coresos.phinf.naver.net/a/xxxx/test.jpg",
                "created_at": 1443691385000,
                "comment_count": 1,
                "emotion_count": 1,
                "is_video_thumbnail": false
            },
            {
                "width": 640,
                "height": 480,
                "photo_key": "AAAVIQRg6e8ld2yf7eQZwWtf",
                "photo_album_key": "AADgiaZXYFi1lV-JpylzUvwO",
                "author": {
                    "name": "Robert J. Lee",
                    "description": "This is description.",
                    "profile_image_url": "http://band.phinf.campmobile.net/20130719_224/xxx/test.jpg"
                },
                "url": "http://beta.coresos.phinf.naver.net/a/xxxx/test.jpg",
                "created_at": 1443690955000,
                "comment_count": 1,
                "emotion_count": 1,
                "is_video_thumbnail": true
            }
        ]
    }
}
EOF

echo ""
echo "💬 3. 사진 댓글 API 테스트 (일반 댓글 API 사용)"
echo "GET https://openapi.band.us/v2/band/post/comments?post_key=PHOTO_KEY"
echo ""
echo "📝 사진도 post_key로 취급되어 일반 댓글 API를 사용합니다."

echo ""
echo "✅ API 구조 분석 완료!"
echo "   - 앨범: photo_album_key 사용"
echo "   - 사진: photo_key 사용 (댓글 조회시 post_key로 활용)"
echo "   - 작성자: owner 또는 author 필드 (둘 다 지원 필요)"