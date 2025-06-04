defmodule BandCore do
  @moduledoc """
  Band Open API 클라이언트 모듈
  """

  defdelegate get_profile(access_token, band_key \\ nil), to: BandCore.API
  defdelegate get_bands(access_token), to: BandCore.API
  defdelegate get_posts(access_token, band_key, opts \\ []), to: BandCore.API
  defdelegate get_comments(access_token, band_key, post_key, opts \\ []), to: BandCore.API
  defdelegate delete_comment(access_token, band_key, post_key, comment_key), to: BandCore.API
  defdelegate delete_post(access_token, band_key, post_key), to: BandCore.API
  defdelegate delete_all_comments_in_band(access_token, band_key), to: BandCore.CommentManager
  defdelegate delete_comments_by_keyword(access_token, band_key, keyword), to: BandCore.CommentManager
  defdelegate delete_all_posts_in_band(access_token, band_key), to: BandCore.CommentManager
  defdelegate count_all_comments_in_band(access_token, band_key), to: BandCore.CommentManager
  defdelegate count_comments_by_keyword(access_token, band_key, keyword), to: BandCore.CommentManager
  defdelegate count_all_posts_in_band(access_token, band_key), to: BandCore.CommentManager
end
