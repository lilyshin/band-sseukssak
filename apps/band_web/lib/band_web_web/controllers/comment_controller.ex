defmodule BandWebWeb.CommentController do
  use BandWebWeb, :controller

  @doc """
  특정 밴드의 모든 댓글 삭제
  """
  def delete_all(conn, %{"band_key" => band_key, "access_token" => access_token}) do
    case BandCore.delete_all_comments_in_band(access_token, band_key) do
      {:ok, summary} ->
        json(conn, %{
          success: true,
          message: "댓글 삭제가 완료되었습니다",
          data: summary
        })
      
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "댓글 삭제 실패: #{inspect(reason)}"
        })
    end
  end

  def delete_all(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "band_key와 access_token이 필요합니다"
    })
  end

  @doc """
  특정 밴드에서 키워드가 포함된 댓글만 삭제
  """
  def delete_by_keyword(conn, %{"band_key" => band_key, "access_token" => access_token, "keyword" => keyword}) do
    case BandCore.delete_comments_by_keyword(access_token, band_key, keyword) do
      {:ok, summary} ->
        json(conn, %{
          success: true,
          message: "키워드 '#{keyword}' 포함 댓글 삭제가 완료되었습니다",
          data: summary
        })
      
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "댓글 삭제 실패: #{inspect(reason)}"
        })
    end
  end

  def delete_by_keyword(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "band_key, access_token, keyword가 필요합니다"
    })
  end

  @doc """
  특정 밴드의 모든 댓글 개수 확인
  """
  def count_all(conn, %{"band_key" => band_key, "access_token" => access_token}) do
    case BandCore.count_all_comments_in_band(access_token, band_key) do
      {:ok, count} ->
        json(conn, %{
          success: true,
          count: count
        })
      
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "댓글 개수 확인 실패: #{inspect(reason)}"
        })
    end
  end

  @doc """
  특정 밴드에서 키워드가 포함된 댓글 개수 확인
  """
  def count_by_keyword(conn, %{"band_key" => band_key, "access_token" => access_token, "keyword" => keyword}) do
    case BandCore.count_comments_by_keyword(access_token, band_key, keyword) do
      {:ok, count} ->
        json(conn, %{
          success: true,
          count: count
        })
      
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "댓글 개수 확인 실패: #{inspect(reason)}"
        })
    end
  end
end