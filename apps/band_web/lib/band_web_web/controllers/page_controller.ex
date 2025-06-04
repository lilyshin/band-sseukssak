defmodule BandWebWeb.PageController do
  use BandWebWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:flash, %{})
    |> render(:home)
  end

  # 개발용: 에러 페이지 테스트
  def test_error(_conn, %{"type" => "500"}) do
    raise "테스트용 500 에러 - 밴쓱싹 정비 중 페이지 확인!"
  end

  def test_error(conn, %{"type" => "404"}) do
    conn
    |> put_status(:not_found)
    |> put_view(BandWebWeb.ErrorHTML)
    |> render("404.html")
  end

  def test_error(conn, _params) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(BandWebWeb.ErrorHTML)
    |> render("500.html")
  end

  # Catch-all for 404 errors
  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_view(BandWebWeb.ErrorHTML)
    |> render("404.html")
  end
end