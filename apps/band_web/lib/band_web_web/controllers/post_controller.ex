defmodule BandWebWeb.PostController do
  use BandWebWeb, :controller

  @doc """
  특정 밴드의 모든 게시글 삭제
  """
  def delete_all(conn, %{"band_key" => band_key, "access_token" => access_token}) do
    case BandCore.delete_all_posts_in_band(access_token, band_key) do
      {:ok, summary} ->
        json(conn, %{
          success: true,
          message: "게시글 삭제가 완료되었습니다",
          data: summary
        })
      
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "게시글 삭제 실패: #{inspect(reason)}"
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
  특정 밴드의 모든 게시글 개수 확인
  """
  def count_all(conn, %{"band_key" => band_key, "access_token" => access_token}) do
    case BandCore.count_all_posts_in_band(access_token, band_key) do
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
          error: "게시글 개수 확인 실패: #{inspect(reason)}"
        })
    end
  end
end