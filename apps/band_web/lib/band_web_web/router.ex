defmodule BandWebWeb.Router do
  use BandWebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_root_layout, html: {BandWebWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BandWebWeb do
    pipe_through :api
    
    # OAuth 인증 관련 (기존 방식)
    get "/auth/band", AuthController, :auth_url
    get "/auth/band/callback", AuthController, :callback
    post "/auth/band/callback", AuthController, :callback
    
    # 사용자 정보 (기존 방식)
    get "/profile", UserController, :profile
    get "/bands", UserController, :bands
    
    # 댓글 관련
    get "/bands/:band_key/comments/count", CommentController, :count_all
    get "/bands/:band_key/comments/count/keyword", CommentController, :count_by_keyword
    delete "/bands/:band_key/comments", CommentController, :delete_all
    delete "/bands/:band_key/comments/keyword", CommentController, :delete_by_keyword
    
    # 게시글 관련
    get "/bands/:band_key/posts/count", PostController, :count_all
    delete "/bands/:band_key/posts", PostController, :delete_all
    
    # 서버 토큰 프록시 방식 (간편 사용)
    scope "/simple" do
      get "/auth/status", BandProxyController, :check_auth_status
      get "/profile", BandProxyController, :get_user_profile
      get "/bands", BandProxyController, :get_user_bands
      delete "/bands/:band_key/comments", BandProxyController, :delete_band_comments
    end
  end

  scope "/", BandWebWeb do
    pipe_through :browser
    
    get "/", PageController, :home
    get "/maintenance", MaintenanceController, :show
    
    # 개발용: 에러 페이지 테스트
    if Application.compile_env(:band_web, :dev_routes) do
      get "/test-error", PageController, :test_error
      get "/test-error/:type", PageController, :test_error
    end
    
    # Catch-all route for 404 errors (이 라우트는 맨 마지막에 있어야 함)
    get "/*path", PageController, :not_found
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:band_web, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
