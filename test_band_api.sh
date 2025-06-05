#!/bin/bash

# Band API 테스트 스크립트
# 실제 access_token과 band_key를 사용하여 앨범과 사진을 조회합니다.

echo "🧪 Band Open API 직접 테스트"
echo "============================="

# 테스트용 토큰과 밴드 키 (실제 값으로 교체 필요)
ACCESS_TOKEN="${1:-YOUR_ACCESS_TOKEN_HERE}"
BAND_KEY="${2:-YOUR_BAND_KEY_HERE}"

if [ "$ACCESS_TOKEN" = "YOUR_ACCESS_TOKEN_HERE" ] || [ "$BAND_KEY" = "YOUR_BAND_KEY_HERE" ]; then
    echo "❌ 사용법: $0 <access_token> <band_key>"
    echo ""
    echo "예시:"
    echo "$0 \"ZQAAAfqO3iVe...\" \"AABCD1234...\""
    echo ""
    echo "토큰은 프론트엔드 localStorage에서 확인할 수 있습니다:"
    echo "JSON.parse(localStorage.getItem('band_auth_data'))"
    exit 1
fi

echo "🔑 사용할 인증 정보:"
echo "Access Token: ${ACCESS_TOKEN:0:20}..."
echo "Band Key: ${BAND_KEY:0:15}..."
echo ""

# 1. 앨범 목록 조회
echo "📁 1. 앨범 목록 조회"
echo "GET https://openapi.band.us/v2/band/albums"
echo "--------------------------------------------"

ALBUM_RESPONSE=$(curl -s -X GET \
    "https://openapi.band.us/v2/band/albums?access_token=${ACCESS_TOKEN}&band_key=${BAND_KEY}" \
    -H "Content-Type: application/json")

echo "응답:"
echo "$ALBUM_RESPONSE" | jq '.' 2>/dev/null || echo "$ALBUM_RESPONSE"
echo ""

# 첫 번째 앨범 키 추출
FIRST_ALBUM_KEY=$(echo "$ALBUM_RESPONSE" | jq -r '.result_data.items[0].photo_album_key' 2>/dev/null)

if [ "$FIRST_ALBUM_KEY" != "null" ] && [ -n "$FIRST_ALBUM_KEY" ]; then
    echo "✅ 첫 번째 앨범 키: $FIRST_ALBUM_KEY"
    echo ""
    
    # 2. 사진 목록 조회
    echo "📷 2. 사진 목록 조회 (첫 번째 앨범)"
    echo "GET https://openapi.band.us/v2/band/album/photos"
    echo "--------------------------------------------"
    
    PHOTO_RESPONSE=$(curl -s -X GET \
        "https://openapi.band.us/v2/band/album/photos?access_token=${ACCESS_TOKEN}&band_key=${BAND_KEY}&photo_album_key=${FIRST_ALBUM_KEY}" \
        -H "Content-Type: application/json")
    
    echo "응답:"
    echo "$PHOTO_RESPONSE" | jq '.' 2>/dev/null || echo "$PHOTO_RESPONSE"
    echo ""
    
    # 첫 번째 사진 키 추출
    FIRST_PHOTO_KEY=$(echo "$PHOTO_RESPONSE" | jq -r '.result_data.items[0].photo_key' 2>/dev/null)
    
    if [ "$FIRST_PHOTO_KEY" != "null" ] && [ -n "$FIRST_PHOTO_KEY" ]; then
        echo "✅ 첫 번째 사진 키: $FIRST_PHOTO_KEY"
        echo ""
        
        # 3. 사진 댓글 조회 (일반 댓글 API 사용)
        echo "💬 3. 사진 댓글 조회 (post_key로 사용)"
        echo "GET https://openapi.band.us/v2/band/post/comments"
        echo "--------------------------------------------"
        
        COMMENT_RESPONSE=$(curl -s -X GET \
            "https://openapi.band.us/v2/band/post/comments?access_token=${ACCESS_TOKEN}&band_key=${BAND_KEY}&post_key=${FIRST_PHOTO_KEY}" \
            -H "Content-Type: application/json")
        
        echo "응답:"
        echo "$COMMENT_RESPONSE" | jq '.' 2>/dev/null || echo "$COMMENT_RESPONSE"
        echo ""
    else
        echo "⚠️  사진이 없거나 응답 파싱 실패"
    fi
else
    echo "⚠️  앨범이 없거나 응답 파싱 실패"
fi

echo "🏁 API 테스트 완료!"