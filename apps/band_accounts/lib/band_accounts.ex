defmodule BandAccounts do
  @moduledoc """
  Band OAuth 인증 관리 모듈
  """

  defdelegate get_auth_url(client_id, redirect_uri), to: BandAccounts.OAuth
  defdelegate get_access_token(client_id, client_secret, code), to: BandAccounts.OAuth
  defdelegate refresh_token(client_id, client_secret, refresh_token), to: BandAccounts.OAuth
end
