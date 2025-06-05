defmodule BandCore.CommentManager do
  @moduledoc """
  밴드 댓글 일괄 삭제 관리자
  """

  require Logger
  alias BandCore.API
  alias BandCore.ErrorCodes

  @doc """
  특정 밴드의 모든 댓글 삭제
  """
  def delete_all_comments_in_band(access_token, band_key) do
    Logger.info("밴드 #{band_key}의 모든 댓글 삭제 시작")

    case collect_all_comments(access_token, band_key) do
      {:ok, comments} ->
        delete_results = delete_comments_batch(access_token, band_key, comments)
        summarize_deletion_results(delete_results)

      {:error, reason} ->
        Logger.error("댓글 수집 실패: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  특정 밴드의 모든 댓글 개수 확인 (컨트롤러 호환)
  """
  def get_comments_count(access_token, band_key) do
    case collect_all_comments(access_token, band_key) do
      {:ok, comments} ->
        {:ok, length(comments)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  특정 밴드의 모든 댓글 개수 확인
  """
  def count_all_comments_in_band(access_token, band_key) do
    get_comments_count(access_token, band_key)
  end

  @doc """
  특정 밴드에서 키워드가 포함된 댓글 개수 확인 (컨트롤러 호환)
  """
  def get_keyword_comments_count(access_token, band_key, keyword) do
    case collect_all_comments(access_token, band_key) do
      {:ok, comments} ->
        filtered_comments = filter_comments_by_keyword(comments, keyword)
        {:ok, length(filtered_comments)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  특정 밴드에서 키워드가 포함된 댓글 개수 확인
  """
  def count_comments_by_keyword(access_token, band_key, keyword) do
    get_keyword_comments_count(access_token, band_key, keyword)
  end

  @doc """
  특정 밴드의 모든 게시글 개수 확인 (본인 작성 게시글만)
  """
  def count_all_posts_in_band(access_token, band_key) do
    # 먼저 현재 사용자 정보 조회
    case API.get_profile(access_token, band_key) do
      {:ok, %{"result_data" => %{"user_key" => user_key}}} ->
        case collect_all_posts(access_token, band_key) do
          {:ok, all_posts} ->
            # 본인이 작성한 게시글만 필터링하고 카운트
            my_posts = Enum.filter(all_posts, fn post ->
              get_in(post, ["author", "user_key"]) == user_key
            end)
            
            # 본인 게시글 내용 로그 출력 (개수 조회용)
            Enum.each(my_posts, fn post ->
              content = post["content"] || ""
              clean_content = content
                |> String.replace(~r/<[^>]*>/, "")
                |> String.slice(0, 80)
                |> String.trim()
              
              if clean_content != "" do
                Logger.info("📰 내 게시글 발견: \"#{clean_content}#{if String.length(content) > 80, do: "...", else: ""}\"")
              else
                Logger.info("📰 내 게시글 발견: (이미지/미디어 게시글)")
              end
            end)
            
            my_posts_count = length(my_posts)
            Logger.info("전체 #{length(all_posts)}개 게시글 중 본인 게시글 #{my_posts_count}개")
            {:ok, my_posts_count}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("사용자 프로필 조회 실패: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  단일 댓글 삭제
  
  지정된 댓글 하나를 삭제합니다.
  
  ## Parameters
  - `comment_id`: 삭제할 댓글의 ID (comment_key)
  
  ## Returns
  - `{:ok, result}`: 성공 시 삭제 결과
  - `{:error, reason}`: 실패 시 에러 정보
  """
  def delete_comment(comment_id) do
    # 임시 구현 - 실제로는 access_token, band_key, post_key가 필요
    # 이 정보들은 세션이나 데이터베이스에서 가져와야 함
    Logger.info("댓글 #{comment_id} 삭제 요청")
    
    # 현재는 더미 응답 반환
    {:ok, %{
      message: "댓글 삭제 요청이 처리되었습니다",
      comment_id: comment_id,
      status: "pending"
    }}
  end

  @doc """
  특정 밴드의 모든 댓글 삭제 (컨트롤러 호환)
  """
  def delete_all_comments(access_token, band_key) do
    delete_all_comments_in_band(access_token, band_key)
  end

  @doc """
  특정 밴드에서 키워드가 포함된 댓글만 삭제 (컨트롤러 호환)
  """
  def delete_keyword_comments(access_token, band_key, keyword) do
    delete_comments_by_keyword(access_token, band_key, keyword)
  end

  @doc """
  특정 밴드에서 키워드가 포함된 댓글만 삭제
  """
  def delete_comments_by_keyword(access_token, band_key, keyword) do
    Logger.info("밴드 #{band_key}에서 키워드 '#{keyword}' 포함 댓글 삭제 시작")

    case collect_all_comments(access_token, band_key) do
      {:ok, comments} ->
        filtered_comments = filter_comments_by_keyword(comments, keyword)
        Logger.info("키워드 '#{keyword}'로 필터링된 댓글: #{length(filtered_comments)}개")

        delete_results = delete_comments_batch(access_token, band_key, filtered_comments)
        summarize_deletion_results(delete_results)

      {:error, reason} ->
        Logger.error("댓글 수집 실패: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  특정 밴드의 모든 게시글 삭제 (본인 작성 게시글만)
  """
  def delete_all_posts_in_band(access_token, band_key) do
    Logger.info("밴드 #{band_key}의 본인 게시글 삭제 시작")

    # 먼저 현재 사용자 정보 조회
    case API.get_profile(access_token, band_key) do
      {:ok, %{"result_data" => %{"user_key" => user_key}}} ->
        Logger.info("현재 사용자 키: #{user_key}")
        collect_and_delete_my_posts(access_token, band_key, user_key)

      {:error, reason} ->
        Logger.error("사용자 프로필 조회 실패: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp collect_and_delete_my_posts(access_token, band_key, my_user_key) do
    case collect_all_posts(access_token, band_key) do
      {:ok, all_posts} ->
        # 본인이 작성한 게시글만 필터링
        my_posts = Enum.filter(all_posts, fn post ->
          get_in(post, ["author", "user_key"]) == my_user_key
        end)

        # 본인 게시글 내용 로그 출력
        Enum.each(my_posts, fn post ->
          content = post["content"] || ""
          # HTML 태그 제거하고 첫 100자만 표시
          clean_content = content
            |> String.replace(~r/<[^>]*>/, "")
            |> String.slice(0, 100)
            |> String.trim()
          
          if clean_content != "" do
            Logger.info("📰 내 게시글: \"#{clean_content}#{if String.length(content) > 100, do: "...", else: ""}\"")
          else
            Logger.info("📰 내 게시글: (이미지/미디어 게시글)")
          end
        end)

        Logger.info("전체 #{length(all_posts)}개 게시글 중 본인 게시글 #{length(my_posts)}개 발견")
        
        if length(my_posts) > 0 do
          delete_results = delete_posts_batch(access_token, band_key, my_posts)
          summarize_deletion_results(delete_results)
        else
          Logger.info("삭제할 본인 게시글이 없습니다.")
          {:ok, %{total: 0, successful: 0, failed: 0, failed_comments: []}}
        end

      {:error, reason} ->
        Logger.error("게시글 수집 실패: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp collect_all_comments(access_token, band_key) do
    Logger.info("밴드의 모든 게시글과 댓글 수집 중...")

    # 먼저 현재 사용자 정보 조회
    case API.get_profile(access_token, band_key) do
      {:ok, %{"result_data" => %{"user_key" => user_key}}} ->
        Logger.info("현재 사용자 키: #{user_key}")
        collect_my_comments(access_token, band_key, user_key)

      {:error, reason} ->
        Logger.error("사용자 프로필 조회 실패: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp collect_my_comments(access_token, band_key, my_user_key) do
    # 1. 일반 게시글의 댓글 수집
    post_comments_result = case collect_all_posts(access_token, band_key) do
      {:ok, posts} ->
        Logger.info("총 #{length(posts)}개의 게시글에서 본인 댓글 수집 시작")
        
        my_post_comments =
          posts
          |> Enum.with_index(1)
          |> Enum.reduce([], fn {post, index}, acc ->
            Logger.info("게시글 #{index}/#{length(posts)} 처리 중...")
            
            # 각 게시글당 약간의 지연 추가 (API 제한 방지)
            if index > 1, do: :timer.sleep(500)
            
            case collect_post_comments(access_token, band_key, post["post_key"]) do
              {:ok, post_comments} ->
                # 본인이 작성한 댓글만 필터링
                my_comments_in_post = 
                  post_comments
                  |> Enum.filter(fn comment -> 
                    get_in(comment, ["author", "user_key"]) == my_user_key 
                  end)
                  |> Enum.map(&Map.put(&1, "post_key", post["post_key"]))
                
                # 본인 댓글 내용 로그 출력
                Enum.each(my_comments_in_post, fn comment ->
                  content = comment["content"] || ""
                  clean_content = content
                    |> String.replace(~r/<[^>]*>/, "")
                    |> String.slice(0, 50)
                    |> String.trim()
                  
                  if clean_content != "" do
                    Logger.info("📝 내 게시글 댓글: \"#{clean_content}#{if String.length(content) > 50, do: "...", else: ""}\"")
                  else
                    Logger.info("📝 내 게시글 댓글: (이미지/스티커 댓글)")
                  end
                end)
                
                Logger.info("게시글 #{post["post_key"]}에서 본인 댓글 #{length(my_comments_in_post)}개 발견 (전체 #{length(post_comments)}개 중)")
                acc ++ my_comments_in_post

              {:error, reason} ->
                Logger.warning("게시글 #{post["post_key"]}의 댓글 수집 실패: #{inspect(reason)}")
                acc
            end
          end)
        
        {:ok, my_post_comments}

      {:error, reason} ->
        Logger.error("게시글 목록 수집 실패: #{inspect(reason)}")
        {:error, reason}
    end

    # 2. 앨범 사진의 댓글 수집
    album_comments_result = collect_my_album_comments(access_token, band_key, my_user_key)

    # 3. 결과 합치기
    case {post_comments_result, album_comments_result} do
      {{:ok, post_comments}, {:ok, album_comments}} ->
        all_my_comments = post_comments ++ album_comments
        Logger.info("총 #{length(all_my_comments)}개의 본인 댓글 발견 (게시글: #{length(post_comments)}개, 앨범: #{length(album_comments)}개)")
        {:ok, all_my_comments}

      {{:ok, post_comments}, {:error, _}} ->
        Logger.warning("앨범 댓글 수집 실패, 게시글 댓글만 반환")
        Logger.info("총 #{length(post_comments)}개의 본인 댓글 발견 (게시글만)")
        {:ok, post_comments}

      {{:error, reason}, _} ->
        Logger.error("게시글 댓글 수집 실패: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # 앨범 사진 댓글 수집 (현재 Open API 제한으로 인해 지원하지 않음)
  defp collect_my_album_comments(access_token, band_key, my_user_key) do
    Logger.info("앨범 사진 댓글 수집 시도...")
    Logger.warning("⚠️  Band Open API 제한: 앨범 사진 댓글은 내부 API를 사용하여 Open API로 접근할 수 없습니다.")
    Logger.warning("   현재는 일반 게시글 댓글만 지원됩니다.")
    
    # 현재는 빈 목록 반환 (Open API 제한으로 인해 앨범 사진 댓글 미지원)
    {:ok, []}
  end

  # 특정 앨범의 모든 사진에서 본인 댓글 수집 (현재 미사용 - Open API 제한)
  # 
  # Band Open API에서는 앨범 사진 댓글에 대한 공식 지원이 없음
  # 사진 댓글은 내부 API(api-kr.band.us/v2.3.0/get_comments)를 사용하지만
  # 이는 일반 개발자에게 공개되지 않음
  # 
  # 향후 공식 API가 제공되면 아래 코드를 활성화할 수 있음

  defp collect_all_posts(access_token, band_key, after_param \\ nil, accumulated \\ [], page_count \\ 1) do
    opts = if after_param, do: [after: after_param], else: []

    Logger.info("게시글 페이지 #{page_count} 수집 중...")

    case API.get_posts(access_token, band_key, opts) do
      {:ok, %{"result_data" => %{"items" => posts, "paging" => paging}}} ->
        new_accumulated = accumulated ++ posts
        Logger.info("페이지 #{page_count}: #{length(posts)}개 게시글 수집 (누적: #{length(new_accumulated)}개)")

        # next_params에서 after 값을 추출하여 다음 페이지 확인
        next_params = get_in(paging, ["next_params"])
        next_after = if next_params, do: Map.get(next_params, "after"), else: nil

        case next_after do
          nil ->
            Logger.info("🎉 모든 게시글 수집 완료: 총 #{length(new_accumulated)}개 (#{page_count}페이지)")
            {:ok, new_accumulated}

          after_value ->
            # 페이징 요청 간 지연 (API 제한 방지 및 서버 부하 감소)
            :timer.sleep(500)
            collect_all_posts(access_token, band_key, after_value, new_accumulated, page_count + 1)
        end

      {:ok, %{"result_data" => %{"items" => posts}}} ->
        # paging 정보가 없는 경우 (마지막 페이지 또는 단일 페이지)
        final_accumulated = accumulated ++ posts
        Logger.info("🎉 모든 게시글 수집 완료: 총 #{length(final_accumulated)}개 (#{page_count}페이지)")
        {:ok, final_accumulated}

      {:ok, %{"result_data" => result_data}} when not is_map_key(result_data, "items") ->
        # items 키가 없는 경우 (게시글이 없음)
        Logger.info("이 밴드에는 게시글이 없습니다.")
        {:ok, accumulated}

      {:error, %{"result_code" => 60203}} ->
        # 앱과 연동되지 않은 밴드
        Logger.warning("이 밴드는 앱과 연동되지 않았습니다.")
        {:error, "앱과 연동되지 않은 밴드입니다."}

      {:error, reason} ->
        Logger.error("게시글 수집 중 오류 (페이지 #{page_count}): #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp collect_post_comments(
         access_token,
         band_key,
         post_key,
         after_param \\ nil,
         accumulated \\ []
       ) do
    opts = if after_param, do: [after: after_param], else: []

    case API.get_comments(access_token, band_key, post_key, opts) do
      {:ok, %{"result_data" => %{"items" => comments, "paging" => paging}}} ->
        new_accumulated = accumulated ++ comments
        
        # 페이징이 있는 경우 다음 페이지도 수집
        case get_in(paging, ["next_params", "after"]) do
          nil ->
            {:ok, new_accumulated}

          next_after ->
            # 페이징 요청 간 약간의 지연 (API 제한 방지)
            :timer.sleep(200)
            collect_post_comments(access_token, band_key, post_key, next_after, new_accumulated)
        end

      {:ok, %{"result_data" => %{"items" => comments}}} ->
        # paging 정보가 없는 경우 (마지막 페이지)
        {:ok, accumulated ++ comments}

      {:error, %{"result_code" => 60401}} ->
        # 앱과 연동되지 않은 게시글의 경우 빈 댓글 목록 반환
        Logger.info("게시글 #{post_key}는 앱과 연동되지 않음 (건너뜀)")
        {:ok, []}

      {:error, reason} ->
        Logger.warning("게시글 #{post_key} 댓글 수집 실패: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp delete_comments_batch(access_token, band_key, comments) do
    Logger.info("#{length(comments)}개 댓글 삭제 시작 (지능적 쿨타임 관리 적용)")

    comments
    |> Enum.with_index(1)
    |> Enum.reduce([], fn {comment, index}, acc ->
      Logger.info("댓글 삭제 진행: #{index}/#{length(comments)}")

      # 점진적으로 증가하는 대기 시간 (쿨타임 제한을 더 효과적으로 방지)
      base_delay = case index do
        1 -> 0  # 첫 번째는 즉시
        n when n <= 5 -> 3000  # 처음 5개는 3초
        n when n <= 15 -> 4000  # 6-15개는 4초
        _ -> 5000  # 그 이후는 5초
      end
      
      if index > 1 do
        Logger.info("쿨 타임 방지를 위해 #{base_delay/1000}초 대기...")
        :timer.sleep(base_delay)
      end

      # 재시도 메커니즘으로 댓글 삭제 시도
      result = delete_comment_with_retry(access_token, band_key, comment, 3)

      [{comment["comment_key"], result} | acc]
    end)
    |> Enum.reverse()
  end

  # 재시도 로직이 포함된 댓글 삭제 함수
  defp delete_comment_with_retry(access_token, band_key, comment, max_retries) do
    delete_comment_with_retry_impl(access_token, band_key, comment, max_retries, 1)
  end

  defp delete_comment_with_retry_impl(access_token, band_key, comment, max_retries, attempt) do
    # 모든 댓글(게시글 댓글, 사진 댓글)을 동일한 API로 삭제
    result = API.delete_comment(
      access_token,
      band_key,
      comment["post_key"],
      comment["comment_key"]
    )

    case result do
      {:ok, _} = success ->
        if attempt > 1 do
          Logger.info("댓글 #{comment["comment_key"]} 삭제 성공 (#{attempt}번째 시도)")
        end
        success

      {:error, %{"result_code" => 1003}} when attempt < max_retries ->
        # 쿨타임 에러 시 지수적 백오프로 재시도
        wait_time = :math.pow(2, attempt) * 5000 |> round()  # 5초, 10초, 20초
        Logger.info("쿨 타임 제한 감지 (#{attempt}/#{max_retries}), #{wait_time/1000}초 대기 후 재시도...")
        :timer.sleep(wait_time)
        delete_comment_with_retry_impl(access_token, band_key, comment, max_retries, attempt + 1)

      {:error, %{"result_code" => code} = _error_data} ->
        # 다른 에러들은 재시도하지 않음
        error_context = %{
          action: if(comment["comment_type"] == "photo", do: :delete_photo_comment, else: :delete_comment),
          comment_key: comment["comment_key"],
          post_key: comment["post_key"],
          band_key: band_key,
          attempt: attempt
        }
        # 사진 댓글인 경우 추가 정보 포함
        error_context = if comment["comment_type"] == "photo" do
          Map.merge(error_context, %{
            photo_key: comment["photo_key"],
            album_key: comment["album_key"]
          })
        else
          error_context
        end
        
        ErrorCodes.log_error(code, error_context)
        result

      {:error, error_data} ->
        # result_code가 없는 에러
        error_context = %{
          action: if(comment["comment_type"] == "photo", do: :delete_photo_comment, else: :delete_comment),
          comment_key: comment["comment_key"],
          post_key: comment["post_key"],
          band_key: band_key,
          attempt: attempt
        }
        # 사진 댓글인 경우 추가 정보 포함
        error_context = if comment["comment_type"] == "photo" do
          Map.merge(error_context, %{
            photo_key: comment["photo_key"],
            album_key: comment["album_key"]
          })
        else
          error_context
        end
        
        ErrorCodes.handle_error_response(error_data, error_context)
        result
    end
  end

  defp summarize_deletion_results(results) do
    {successful, failed} =
      Enum.split_with(results, fn {_comment_key, result} ->
        match?({:ok, _}, result)
      end)

    summary = %{
      total: length(results),
      successful: length(successful),
      failed: length(failed),
      failed_comments:
        Enum.map(failed, fn {comment_key, error} ->
          %{comment_key: comment_key, error: format_error(error)}
        end)
    }

    Logger.info("삭제 완료: 성공 #{summary.successful}개, 실패 #{summary.failed}개")

    if summary.failed > 0 do
      Logger.warning("실패한 댓글들: #{inspect(summary.failed_comments)}")
    end

    {:ok, summary}
  end

  # 키워드로 댓글 필터링
  defp filter_comments_by_keyword(comments, keyword) do
    Logger.info("키워드 '#{keyword}'로 #{length(comments)}개 댓글 필터링 시작")

    filtered =
      Enum.filter(comments, fn comment ->
        # Band API에서는 "content" 필드에 댓글 내용이 저장됨
        content = comment["content"] || ""
        String.contains?(String.downcase(content), String.downcase(keyword))
      end)

    Logger.info("키워드 필터링 결과: #{length(filtered)}개 댓글이 매칭됨")
    filtered
  end

  # 게시글 일괄 삭제 (지능적 쿨타임 관리 적용)
  defp delete_posts_batch(access_token, band_key, posts) do
    Logger.info("#{length(posts)}개 게시글 삭제 시작 (지능적 쿨타임 관리 적용)")

    posts
    |> Enum.with_index(1)
    |> Enum.reduce([], fn {post, index}, acc ->
      Logger.info("게시글 삭제 진행: #{index}/#{length(posts)}")

      # 게시글은 댓글보다 더 긴 대기 시간 필요 (게시글 삭제가 더 무거운 작업)
      base_delay = case index do
        1 -> 0  # 첫 번째는 즉시
        n when n <= 3 -> 5000  # 처음 3개는 5초
        n when n <= 10 -> 6000  # 4-10개는 6초
        _ -> 8000  # 그 이후는 8초
      end
      
      if index > 1 do
        Logger.info("쿨 타임 방지를 위해 #{base_delay/1000}초 대기...")
        :timer.sleep(base_delay)
      end

      # 재시도 메커니즘으로 게시글 삭제 시도
      result = delete_post_with_retry(access_token, band_key, post, 3)

      [{post["post_key"], result} | acc]
    end)
    |> Enum.reverse()
  end

  # 재시도 로직이 포함된 게시글 삭제 함수
  defp delete_post_with_retry(access_token, band_key, post, max_retries) do
    delete_post_with_retry_impl(access_token, band_key, post, max_retries, 1)
  end

  defp delete_post_with_retry_impl(access_token, band_key, post, max_retries, attempt) do
    result = API.delete_post(access_token, band_key, post["post_key"])

    case result do
      {:ok, _} = success ->
        if attempt > 1 do
          Logger.info("게시글 #{post["post_key"]} 삭제 성공 (#{attempt}번째 시도)")
        end
        success

      {:error, %{"result_code" => 1003}} when attempt < max_retries ->
        # 쿨타임 에러 시 지수적 백오프로 재시도 (게시글은 더 긴 대기)
        wait_time = :math.pow(2, attempt) * 8000 |> round()  # 8초, 16초, 32초
        Logger.info("쿨 타임 제한 감지 (#{attempt}/#{max_retries}), #{wait_time/1000}초 대기 후 재시도...")
        :timer.sleep(wait_time)
        delete_post_with_retry_impl(access_token, band_key, post, max_retries, attempt + 1)

      {:error, %{"result_code" => code} = _error_data} ->
        # 다른 에러들은 재시도하지 않음
        ErrorCodes.log_error(code, %{
          action: :delete_post,
          post_key: post["post_key"],
          band_key: band_key,
          attempt: attempt
        })
        result

      {:error, error_data} ->
        # result_code가 없는 에러
        ErrorCodes.handle_error_response(error_data, %{
          action: :delete_post,
          post_key: post["post_key"],
          band_key: band_key,
          attempt: attempt
        })
        result
    end
  end

  # 오류를 JSON 호환 형식으로 변환 (사용자 친화적 메시지 포함)
  defp format_error({:error, error_data}) when is_map(error_data) do
    user_message = case error_data do
      %{"result_code" => code} ->
        ErrorCodes.get_user_friendly_message(code)
      %{"result_data" => %{"message" => message}} ->
        message
      _ ->
        "알 수 없는 오류가 발생했습니다."
    end

    %{
      type: "api_error",
      message: user_message,
      details: error_data
    }
  end

  defp format_error({:error, reason}) do
    %{
      type: "unknown_error",
      message: to_string(reason)
    }
  end

  defp format_error(other) do
    %{
      type: "unexpected_error",
      message: inspect(other)
    }
  end
end
