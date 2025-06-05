defmodule BandCore.API do
  @moduledoc """
  Band Open API 클라이언트 모듈
  
  이 모듈은 밴드 오픈 API와의 HTTP 통신을 담당합니다.
  모든 API 호출에 대한 공통 에러 처리와 응답 파싱을 제공합니다.
  
  ## 지원하는 API
  - 사용자 프로필 조회 (`get_profile/2`)
  - 밴드 목록 조회 (`get_bands/1`)  
  - 게시글 목록 조회 (`get_posts/3`)
  - 댓글 목록 조회 (`get_comments/4`)
  - 댓글 삭제 (`delete_comment/4`)
  
  ## 에러 처리
  - 성공: `{:ok, response_data}` (result_code가 1인 경우)
  - API 에러: `{:error, error_data}` (result_code가 1이 아닌 경우)
  - HTTP 에러: `{:error, {status_code, error_data}}`
  - JSON 파싱 에러: `{:error, :invalid_response}`
  - 네트워크 에러: `{:error, HTTPoison.Error.t()}`
  
  ## 참고사항
  - 모든 요청에는 유효한 access_token이 필요합니다
  - 페이징 지원 API는 `opts` 파라미터로 페이징 옵션을 전달할 수 있습니다
  """

  alias BandCore.ErrorCodes

  # Band Open API 서버의 기본 URL
  # 테스트 환경에서는 Application.get_env로 override 가능
  @api_base_url Application.compile_env(:band_core, :api_base_url, "https://openapi.band.us")

  @doc """
  사용자 프로필 정보 조회
  
  로그인한 사용자의 프로필 정보를 가져옵니다.
  밴드 키를 지정하면 해당 밴드에서의 프로필을, 
  지정하지 않으면 기본 프로필을 조회합니다.
  
  ## Parameters
  - `access_token`: 사용자 인증 토큰
  - `band_key`: (선택) 특정 밴드의 프로필을 조회할 때 사용
  
  ## Returns
  - `{:ok, profile_data}`: 성공 시 프로필 정보
    - `result_data.user_key`: 사용자 식별자
    - `result_data.name`: 사용자 이름
    - `result_data.profile_image_url`: 프로필 이미지 URL
    - `result_data.is_app_member`: 서비스 연동 여부
    - `result_data.message_allowed`: 메시지 수신 허용 여부
  - `{:error, reason}`: 실패 시 에러 정보
  
  ## Examples
      # 기본 프로필 조회
      {:ok, profile} = BandCore.API.get_profile("access_token")
      
      # 특정 밴드에서의 프로필 조회
      {:ok, band_profile} = BandCore.API.get_profile("access_token", "band_key")
  """
  def get_profile(access_token, band_key \\ nil) do
    # 기본 파라미터 설정
    params = %{access_token: access_token}
    
    # band_key가 제공된 경우 파라미터에 추가
    params = if band_key, do: Map.put(params, :band_key, band_key), else: params
    
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2/profile"
    make_request(:get, url, params)
  end

  @doc """
  사용자가 가입한 밴드 목록 조회
  
  로그인한 사용자가 가입한 모든 밴드의 목록을 조회합니다.
  각 밴드의 기본 정보(이름, 키, 커버 이미지, 멤버 수)를 제공합니다.
  
  ## Parameters
  - `access_token`: 사용자 인증 토큰
  
  ## Returns
  - `{:ok, bands_data}`: 성공 시 밴드 목록
    - `result_data.bands`: 밴드 목록 배열
      - `name`: 밴드 이름
      - `band_key`: 밴드 식별자
      - `cover`: 밴드 커버 이미지 URL
      - `member_count`: 밴드 멤버 수
  - `{:error, reason}`: 실패 시 에러 정보
  
  ## Examples
      {:ok, response} = BandCore.API.get_bands("access_token")
      bands = response["result_data"]["bands"]
      Enum.each(bands, fn band ->
        IO.puts("밴드: \#{band["name"]} (멤버: \#{band["member_count"]}명)")
      end)
  """
  def get_bands(access_token) do
    params = %{access_token: access_token}
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2.1/bands"
    make_request(:get, url, params)
  end

  @doc """
  밴드의 게시글 목록 조회
  
  특정 밴드의 게시글 목록을 조회합니다.
  페이징을 지원하므로 대량의 게시글도 효율적으로 처리할 수 있습니다.
  
  ## Parameters
  - `access_token`: 사용자 인증 토큰
  - `band_key`: 조회할 밴드의 식별자
  - `opts`: (선택) 추가 옵션 키워드 리스트
    - `after`: 페이징을 위한 커서 (이전 응답의 next_params에서 받은 값)
    - `limit`: 한 번에 가져올 게시글 수
    - 기타 밴드 API에서 지원하는 파라미터들
  
  ## Returns
  - `{:ok, posts_data}`: 성공 시 게시글 목록
    - `result_data.items`: 게시글 배열
      - `post_key`: 게시글 식별자
      - `content`: 게시글 내용
      - `created_at`: 작성일 (epoch time)
      - 기타 게시글 정보
    - `result_data.paging`: 페이징 정보
      - `next_params`: 다음 페이지 요청 파라미터
  - `{:error, reason}`: 실패 시 에러 정보
  
  ## Examples
      # 첫 페이지 조회
      {:ok, posts} = BandCore.API.get_posts("token", "band_key")
      
      # 페이징으로 다음 페이지 조회
      next_opts = posts["result_data"]["paging"]["next_params"]
      {:ok, more_posts} = BandCore.API.get_posts("token", "band_key", next_opts)
  """
  def get_posts(access_token, band_key, opts \\ []) do
    # 필수 파라미터 설정
    params = %{
      access_token: access_token,
      band_key: band_key,
      locale: "ko_KR"  # 한국어 로케일 기본값
    }
    # 선택적 파라미터 병합 (페이징, 로케일 변경 등)
    |> Map.merge(Enum.into(opts, %{}))
    
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2/band/posts"
    make_request(:get, url, params)
  end

  @doc """
  특정 게시글의 댓글 목록 조회
  
  지정된 게시글에 달린 모든 댓글을 조회합니다.
  페이징을 지원하므로 대량의 댓글도 효율적으로 처리할 수 있습니다.
  
  ## Parameters
  - `access_token`: 사용자 인증 토큰
  - `band_key`: 밴드 식별자
  - `post_key`: 게시글 식별자
  - `opts`: (선택) 추가 옵션 키워드 리스트
    - `after`: 페이징을 위한 커서
    - `sort`: 정렬 방식 ("+created_at" 또는 "-created_at")
    - 기타 댓글 API에서 지원하는 파라미터들
  
  ## Returns
  - `{:ok, comments_data}`: 성공 시 댓글 목록
    - `result_data.items`: 댓글 배열
      - `comment_key`: 댓글 식별자
      - `content`: 댓글 내용
      - `author`: 작성자 정보
      - `created_at`: 작성일 (epoch time)
      - `emotion_count`: 감정 아이콘 수
    - `result_data.paging`: 페이징 정보
  - `{:error, reason}`: 실패 시 에러 정보
  
  ## Examples
      # 기본 댓글 조회 (생성순)
      {:ok, comments} = BandCore.API.get_comments("token", "band_key", "post_key")
      
      # 최신순으로 댓글 조회
      {:ok, comments} = BandCore.API.get_comments("token", "band_key", "post_key", 
                                                  sort: "-created_at")
  """
  def get_comments(access_token, band_key, post_key, opts \\ []) do
    # 필수 파라미터 설정
    params = %{
      access_token: access_token,
      band_key: band_key,
      post_key: post_key
    }
    # 선택적 파라미터 병합 (페이징, 정렬 등)
    |> Map.merge(Enum.into(opts, %{}))
    
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2/band/post/comments"
    make_request(:get, url, params)
  end

  @doc """
  특정 댓글 삭제
  
  지정된 댓글을 삭제합니다.
  동일한 Client ID에서 작성된 댓글만 삭제할 수 있습니다.
  
  ## Parameters
  - `access_token`: 사용자 인증 토큰
  - `band_key`: 밴드 식별자
  - `post_key`: 게시글 식별자
  - `comment_key`: 삭제할 댓글의 식별자
  
  ## Returns
  - `{:ok, delete_result}`: 성공 시 삭제 결과
    - `result_data.message`: "success" 메시지
  - `{:error, reason}`: 실패 시 에러 정보
    - 권한 없음 (본인이 작성한 댓글이 아님)
    - 존재하지 않는 댓글
    - 기타 API 에러
  
  ## Examples
      {:ok, result} = BandCore.API.delete_comment("token", "band_key", "post_key", "comment_key")
      # result["result_data"]["message"] => "success"
      
  ## Notes
  - 삭제된 댓글은 복구할 수 없습니다
  - 다른 사용자가 작성한 댓글은 삭제할 수 없습니다
  """
  def delete_comment(access_token, band_key, post_key, comment_key) do
    params = %{
      access_token: access_token,
      band_key: band_key,
      post_key: post_key,
      comment_key: comment_key
    }
    
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2/band/post/comment/remove"
    make_request(:post, url, params)
  end

  @doc """
  특정 밴드의 게시글 개수 조회
  
  모든 페이지를 순회하여 전체 게시글 개수를 정확히 계산합니다.
  """
  def get_posts_count(access_token, band_key) do
    case BandCore.CommentManager.count_all_posts_in_band(access_token, band_key) do
      {:ok, count} -> {:ok, count}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  특정 밴드의 모든 게시글 삭제
  """
  def delete_all_posts(access_token, band_key) do
    case BandCore.CommentManager.delete_all_posts_in_band(access_token, band_key) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  특정 밴드의 앨범 목록 조회
  
  밴드의 모든 앨범을 조회합니다.
  """
  def get_albums(access_token, band_key, opts \\ []) do
    params = %{
      access_token: access_token,
      band_key: band_key,
      locale: "ko_KR"
    }
    |> Map.merge(Enum.into(opts, %{}))
    
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2/band/albums"
    make_request(:get, url, params)
  end

  @doc """
  특정 앨범의 사진 목록 조회
  
  앨범에 있는 모든 사진을 조회합니다.
  """
  def get_album_photos(access_token, band_key, album_key, opts \\ []) do
    params = %{
      access_token: access_token,
      band_key: band_key,
      photo_album_key: album_key,
      locale: "ko_KR"
    }
    |> Map.merge(Enum.into(opts, %{}))
    
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2/band/album/photos"
    make_request(:get, url, params)
  end

  @doc """
  특정 사진의 댓글 목록 조회
  
  앨범 사진에 달린 댓글을 조회합니다.
  Band API에서 사진도 post로 취급되므로 post_key로 전달합니다.
  """
  def get_photo_comments(access_token, band_key, photo_key, opts \\ []) do
    params = %{
      access_token: access_token,
      band_key: band_key,
      post_key: photo_key
    }
    |> Map.merge(Enum.into(opts, %{}))
    
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2/band/post/comments"
    make_request(:get, url, params)
  end

  @doc """
  특정 사진 댓글 삭제
  
  앨범 사진의 댓글을 삭제합니다.
  Band API에서 사진도 post로 취급되므로 일반 댓글 삭제 API를 사용합니다.
  """
  def delete_photo_comment(access_token, band_key, photo_key, comment_key) do
    params = %{
      access_token: access_token,
      band_key: band_key,
      post_key: photo_key,
      comment_key: comment_key
    }
    
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2/band/post/comment/remove"
    make_request(:post, url, params)
  end

  @doc """
  특정 게시글 삭제
  
  지정된 게시글을 삭제합니다.
  동일한 Client ID에서 작성된 게시글만 삭제할 수 있습니다.
  
  ## Parameters
  - `access_token`: 사용자 인증 토큰
  - `band_key`: 밴드 식별자
  - `post_key`: 삭제할 게시글의 식별자
  
  ## Returns
  - `{:ok, delete_result}`: 성공 시 삭제 결과
    - `result_data.message`: "success" 메시지
  - `{:error, reason}`: 실패 시 에러 정보
    - 권한 없음 (본인이 작성한 게시글이 아님)
    - 존재하지 않는 게시글
    - 기타 API 에러
  
  ## Examples
      {:ok, result} = BandCore.API.delete_post("token", "band_key", "post_key")
      # result["result_data"]["message"] => "success"
      
  ## Notes
  - 삭제된 게시글은 복구할 수 없습니다
  - 다른 사용자가 작성한 게시글은 삭제할 수 없습니다
  - 게시글 삭제시 해당 게시글의 모든 댓글도 함께 삭제됩니다
  """
  def delete_post(access_token, band_key, post_key) do
    params = %{
      access_token: access_token,
      band_key: band_key,
      post_key: post_key
    }
    
    base_url = Application.get_env(:band_core, :api_base_url, @api_base_url)
    url = "#{base_url}/v2/band/post/remove"
    make_request(:post, url, params)
  end

  # GET 요청 처리
  # 
  # 쿼리 파라미터를 URL에 인코딩하여 GET 요청을 보냅니다.
  # 밴드 API의 조회 계열 API들이 GET 방식을 사용합니다.
  defp make_request(:get, url, params) do
    # 파라미터를 URL 쿼리 스트링으로 인코딩
    query_string = URI.encode_query(params)
    full_url = "#{url}?#{query_string}"
    
    case HTTPoison.get(full_url) do
      # HTTP 200 OK 응답
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          # 밴드 API 성공 응답 (result_code: 1)
          {:ok, %{"result_code" => 1} = data} -> {:ok, data}
          # 밴드 API 에러 응답 (result_code가 1이 아님)
          {:ok, %{"result_code" => code} = error_data} ->
            # 에러 코드 로깅
            ErrorCodes.log_error(code, %{
              url: url,
              params: params,
              method: :get
            })
            {:error, error_data}
          {:ok, error_data} -> 
            # result_code가 없는 에러 응답
            ErrorCodes.handle_error_response(error_data, %{
              url: url,
              params: params,
              method: :get
            })
            {:error, error_data}
          # JSON 파싱 실패
          {:error, _} -> {:error, :invalid_response}
        end
      
      # HTTP 에러 응답 (4xx, 5xx)
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        case Jason.decode(body) do
          {:ok, error_data} -> {:error, {status_code, error_data}}
          {:error, _} -> {:error, {status_code, :invalid_response}}
        end
      
      # 네트워크 에러 (연결 실패, 타임아웃 등)
      {:error, error} ->
        {:error, error}
    end
  end

  # POST 요청 처리
  # 
  # 파라미터를 form-urlencoded 형태로 요청 본문에 담아 POST 요청을 보냅니다.
  # 밴드 API의 변경 계열 API들(댓글 삭제 등)이 POST 방식을 사용합니다.
  defp make_request(:post, url, params) do
    # Content-Type을 form-urlencoded로 설정 (밴드 API 요구사항)
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    # 파라미터를 form-urlencoded 형태로 인코딩
    body = URI.encode_query(params)
    
    case HTTPoison.post(url, body, headers) do
      # HTTP 200 OK 응답
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          # 밴드 API 성공 응답
          {:ok, %{"result_code" => 1} = data} -> {:ok, data}
          # 밴드 API 에러 응답 (result_code가 1이 아님)
          {:ok, %{"result_code" => code} = error_data} ->
            # 에러 코드 로깅
            ErrorCodes.log_error(code, %{
              url: url,
              params: params,
              method: :post
            })
            {:error, error_data}
          {:ok, error_data} -> 
            # result_code가 없는 에러 응답
            ErrorCodes.handle_error_response(error_data, %{
              url: url,
              params: params,
              method: :post
            })
            {:error, error_data}
          # JSON 파싱 실패
          {:error, _} -> {:error, :invalid_response}
        end
      
      # HTTP 에러 응답
      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, error_data} -> {:error, {status_code, error_data}}
          {:error, _} -> {:error, {status_code, :invalid_response}}
        end
      
      # 네트워크 에러
      {:error, error} ->
        {:error, error}
    end
  end
end