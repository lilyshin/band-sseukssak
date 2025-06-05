defmodule BandApiWeb.Router do
  use BandApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["http://localhost:3000"]
  end

  scope "/api", BandApiWeb do
    pipe_through :api

    # 밴드 목록 조회
    get "/bands", BandController, :get_bands

    # 밴드별 통계 및 대량 작업 API
    scope "/bands/:band_key" do
      # 댓글 관련
      get "/comments/count", BandController, :get_comments_count
      get "/comments/count/keyword", BandController, :get_keyword_comments_count
      delete "/comments", BandController, :delete_all_comments
      delete "/comments/keyword", BandController, :delete_keyword_comments
      
      # 게시글 관련
      get "/posts/count", BandController, :get_posts_count
      delete "/posts", BandController, :delete_all_posts
    end

    # Band Core API - 직접 컨트롤러 사용
    scope "/band" do
      get "/comments/:post_id", BandController, :get_comments
      delete "/comments/:comment_id", BandController, :delete_comment
      delete "/posts/:post_id", BandController, :delete_post
    end

    # Band Accounts API - OAuth 관련
    scope "/auth" do
      get "/band", AuthController, :auth_url
      get "/oauth/callback", AuthController, :oauth_callback
      post "/oauth/token", AuthController, :get_token
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:band_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: BandApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
