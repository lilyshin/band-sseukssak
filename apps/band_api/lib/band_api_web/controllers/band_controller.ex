defmodule BandApiWeb.BandController do
  use BandApiWeb, :controller

  @doc """
  사용자가 가입한 밴드 목록 조회
  
  밴드 API: GET /v2/bands
  """
  def get_bands(conn, params) do
    access_token = get_access_token(params)
    
    case access_token do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      token ->
        case BandCore.API.get_bands(token) do
          {:ok, bands} ->
            json(conn, %{success: true, data: bands})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end

  @doc """
  특정 게시글의 댓글 목록 조회
  
  밴드 API: GET /v2/band/post/comments
  """
  def get_comments(conn, %{"post_id" => post_id} = params) do
    access_token = get_access_token(params)
    band_key = Map.get(params, "band_key")
    sort = Map.get(params, "sort", "+created_at")
    
    case {access_token, band_key} do
      {nil, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      {_, nil} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "band_key가 필요합니다"})
      
      {token, band_key} ->
        opts = [sort: sort]
        case BandCore.API.get_comments(token, band_key, post_id, opts) do
          {:ok, comments} ->
            json(conn, %{success: true, data: comments})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end


  @doc """
  특정 댓글 삭제
  
  밴드 API: POST /v2/band/post/comment/remove
  """
  def delete_comment(conn, %{"comment_id" => comment_id} = params) do
    access_token = get_access_token(params)
    band_key = Map.get(params, "band_key")
    post_id = Map.get(params, "post_id")
    
    case {access_token, band_key, post_id} do
      {nil, _, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      {_, nil, _} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "band_key가 필요합니다"})
      
      {_, _, nil} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "post_id가 필요합니다"})
      
      {token, band_key, post_id} ->
        case BandCore.API.delete_comment(token, band_key, post_id, comment_id) do
          {:ok, result} ->
            json(conn, %{success: true, data: result})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end


  @doc """
  특정 게시글 삭제
  
  밴드 API: POST /v2/band/post/remove
  """
  def delete_post(conn, %{"post_id" => post_id} = params) do
    access_token = get_access_token(params)
    band_key = Map.get(params, "band_key")
    
    case {access_token, band_key} do
      {nil, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      {_, nil} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "band_key가 필요합니다"})
      
      {token, band_key} ->
        case BandCore.API.delete_post(token, band_key, post_id) do
          {:ok, result} ->
            json(conn, %{success: true, data: result})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end

  @doc """
  특정 밴드의 댓글 개수 조회
  """
  def get_comments_count(conn, %{"band_key" => band_key} = params) do
    access_token = get_access_token(params)
    
    case access_token do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      token ->
        case BandCore.CommentManager.get_comments_count(token, band_key) do
          {:ok, count} ->
            json(conn, %{success: true, data: %{count: count}})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end

  @doc """
  특정 밴드의 키워드 댓글 개수 조회
  """
  def get_keyword_comments_count(conn, %{"band_key" => band_key} = params) do
    access_token = get_access_token(params)
    keyword = Map.get(params, "keyword")
    
    case {access_token, keyword} do
      {nil, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      {_, nil} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "keyword가 필요합니다"})
      
      {token, keyword} ->
        case BandCore.CommentManager.get_keyword_comments_count(token, band_key, keyword) do
          {:ok, count} ->
            json(conn, %{success: true, data: %{count: count}})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end

  @doc """
  특정 밴드의 게시글 개수 조회
  """
  def get_posts_count(conn, %{"band_key" => band_key} = params) do
    access_token = get_access_token(params)
    
    case access_token do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      token ->
        case BandCore.API.get_posts_count(token, band_key) do
          {:ok, count} ->
            json(conn, %{success: true, data: %{count: count}})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end

  @doc """
  특정 밴드의 모든 댓글 삭제
  """
  def delete_all_comments(conn, %{"band_key" => band_key} = params) do
    access_token = get_access_token(params)
    
    case access_token do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      token ->
        case BandCore.CommentManager.delete_all_comments(token, band_key) do
          {:ok, result} ->
            json(conn, %{success: true, data: result})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end

  @doc """
  특정 밴드의 키워드 댓글 삭제
  """
  def delete_keyword_comments(conn, %{"band_key" => band_key} = params) do
    access_token = get_access_token(params)
    keyword = Map.get(params, "keyword")
    
    case {access_token, keyword} do
      {nil, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      {_, nil} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "keyword가 필요합니다"})
      
      {token, keyword} ->
        case BandCore.CommentManager.delete_keyword_comments(token, band_key, keyword) do
          {:ok, result} ->
            json(conn, %{success: true, data: result})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end

  @doc """
  특정 밴드의 모든 게시글 삭제
  """
  def delete_all_posts(conn, %{"band_key" => band_key} = params) do
    access_token = get_access_token(params)
    
    case access_token do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "access_token이 필요합니다"})
      
      token ->
        case BandCore.API.delete_all_posts(token, band_key) do
          {:ok, result} ->
            json(conn, %{success: true, data: result})
          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{success: false, error: reason})
        end
    end
  end

  # 파라미터나 헤더에서 access_token 추출
  defp get_access_token(params) do
    Map.get(params, "access_token")
  end
end