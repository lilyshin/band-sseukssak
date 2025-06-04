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
  특정 밴드의 모든 댓글 개수 확인
  """
  def count_all_comments_in_band(access_token, band_key) do
    case collect_all_comments(access_token, band_key) do
      {:ok, comments} ->
        {:ok, length(comments)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  특정 밴드에서 키워드가 포함된 댓글 개수 확인
  """
  def count_comments_by_keyword(access_token, band_key, keyword) do
    case collect_all_comments(access_token, band_key) do
      {:ok, comments} ->
        filtered_comments = filter_comments_by_keyword(comments, keyword)
        {:ok, length(filtered_comments)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  특정 밴드의 모든 게시글 개수 확인
  """
  def count_all_posts_in_band(access_token, band_key) do
    case collect_all_posts(access_token, band_key) do
      {:ok, posts} ->
        {:ok, length(posts)}

      {:error, reason} ->
        {:error, reason}
    end
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
  특정 밴드의 모든 게시글 삭제
  """
  def delete_all_posts_in_band(access_token, band_key) do
    Logger.info("밴드 #{band_key}의 모든 게시글 삭제 시작")

    case collect_all_posts(access_token, band_key) do
      {:ok, posts} ->
        delete_results = delete_posts_batch(access_token, band_key, posts)
        summarize_deletion_results(delete_results)

      {:error, reason} ->
        Logger.error("게시글 수집 실패: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp collect_all_comments(access_token, band_key) do
    Logger.info("밴드의 모든 게시글과 댓글 수집 중...")

    case collect_all_posts(access_token, band_key) do
      {:ok, posts} ->
        comments =
          posts
          |> Enum.flat_map(fn post ->
            case collect_post_comments(access_token, band_key, post["post_key"]) do
              {:ok, post_comments} ->
                Enum.map(post_comments, &Map.put(&1, "post_key", post["post_key"]))

              {:error, _} ->
                Logger.warning("게시글 #{post["post_key"]}의 댓글 수집 실패")
                []
            end
          end)

        Logger.info("총 #{length(comments)}개의 댓글 발견")
        {:ok, comments}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp collect_all_posts(access_token, band_key, after_param \\ nil, accumulated \\ []) do
    opts = if after_param, do: [after: after_param], else: []

    case API.get_posts(access_token, band_key, opts) do
      {:ok, %{"result_data" => %{"items" => posts, "paging" => paging}}} ->
        new_accumulated = accumulated ++ posts

        case get_in(paging, ["next_params", "after"]) do
          nil ->
            {:ok, new_accumulated}

          next_after ->
            collect_all_posts(access_token, band_key, next_after, new_accumulated)
        end

      {:error, reason} ->
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

        case get_in(paging, ["next_params", "after"]) do
          nil ->
            {:ok, new_accumulated}

          next_after ->
            collect_post_comments(access_token, band_key, post_key, next_after, new_accumulated)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp delete_comments_batch(access_token, band_key, comments) do
    Logger.info("#{length(comments)}개 댓글 삭제 시작")

    comments
    |> Enum.with_index(1)
    |> Enum.map(fn {comment, index} ->
      Logger.info("댓글 삭제 진행: #{index}/#{length(comments)}")

      # 쿨 타임 제한을 피하기 위해 댓글 간 2초 대기
      if index > 1 do
        Logger.info("쿨 타임 방지를 위해 2초 대기...")
        :timer.sleep(2000)
      end

      result =
        API.delete_comment(
          access_token,
          band_key,
          comment["post_key"],
          comment["comment_key"]
        )

      # 실패시 에러 로깅 및 추가 대기
      case result do
        {:error, %{"result_code" => code} = error_data} when code == 1003 ->
          Logger.info("쿨 타임 제한 감지, 10초 추가 대기...")
          :timer.sleep(10000)
          
        {:error, %{"result_code" => code} = error_data} ->
          # 에러 코드 로깅
          ErrorCodes.log_error(code, %{
            action: :delete_comment,
            comment_key: comment["comment_key"],
            post_key: comment["post_key"],
            band_key: band_key
          })

        {:error, error_data} ->
          # result_code가 없는 에러
          ErrorCodes.handle_error_response(error_data, %{
            action: :delete_comment,
            comment_key: comment["comment_key"],
            post_key: comment["post_key"],
            band_key: band_key
          })

        _ ->
          :ok
      end

      {comment["comment_key"], result}
    end)
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

  # 게시글 일괄 삭제
  defp delete_posts_batch(access_token, band_key, posts) do
    Logger.info("#{length(posts)}개 게시글 삭제 시작")

    posts
    |> Enum.with_index(1)
    |> Enum.map(fn {post, index} ->
      Logger.info("게시글 삭제 진행: #{index}/#{length(posts)}")

      # 쿨 타임 제한을 피하기 위해 게시글 간 3초 대기
      if index > 1 do
        Logger.info("쿨 타임 방지를 위해 3초 대기...")
        :timer.sleep(3000)
      end

      result = API.delete_post(access_token, band_key, post["post_key"])

      # 실패시 에러 로깅 및 추가 대기
      case result do
        {:error, %{"result_code" => code} = error_data} when code == 1003 ->
          Logger.info("쿨 타임 제한 감지, 10초 추가 대기...")
          :timer.sleep(10000)
          
        {:error, %{"result_code" => code} = error_data} ->
          # 에러 코드 로깅
          ErrorCodes.log_error(code, %{
            action: :delete_post,
            post_key: post["post_key"],
            band_key: band_key
          })

        {:error, error_data} ->
          # result_code가 없는 에러
          ErrorCodes.handle_error_response(error_data, %{
            action: :delete_post,
            post_key: post["post_key"],
            band_key: band_key
          })

        _ ->
          :ok
      end

      {post["post_key"], result}
    end)
  end

  # 오류를 JSON 호환 형식으로 변환
  defp format_error({:error, error_data}) when is_map(error_data) do
    %{
      type: "api_error",
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
