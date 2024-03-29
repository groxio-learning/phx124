defmodule VitaliWeb.Router do
  use VitaliWeb, :router

  import VitaliWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {VitaliWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", VitaliWeb do
    pipe_through(:browser)

    get("/", PageController, :home)

    live("/counter", CounterLive, :index)
  end

  scope "/admin", VitaliWeb do
    pipe_through([:browser, :require_authenticated_user, :require_admin_user])

    live_session :require_admin_user,
      on_mount: [{VitaliWeb.UserAuth, :ensure_authenticated}, {VitaliWeb.UserAuth, :ensure_admin}] do
      live("/grant", AdminLive, :index)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", VitaliWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:vitali, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through([:browser, :require_authenticated_user, :require_admin_user])

      live_dashboard("/dashboard", metrics: VitaliWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  scope "/", VitaliWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{VitaliWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live("/users/register", UserRegistrationLive, :new)
      live("/users/log_in", UserLoginLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/log_in", UserSessionController, :create)
  end

  scope "/", VitaliWeb do
    pipe_through([:browser, :require_authenticated_user, :show_user_id])

    live_session :require_authenticated_user,
      on_mount: [{VitaliWeb.UserAuth, :ensure_authenticated}] do
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)
    end

    live_session :life_builder,
      on_mount: [{VitaliWeb.UserAuth, :ensure_authenticated}] do
      live("/life/builder/:id", BuilderLive, :edit)
      live("/games", GameLive.Index, :index)
      live("/games/new", GameLive.Index, :new)

      live("/games/:id", GameLive.Show, :show)
      live("/games/:id/show/edit", GameLive.Show, :edit)
      live("/games/:id/run", GameLive.Show)
      live("/games/:id/watch", WatcherLive)
    end
  end

  scope "/", VitaliWeb do
    pipe_through([:browser])

    delete("/users/log_out", UserSessionController, :delete)

    live_session :current_user,
      on_mount: [{VitaliWeb.UserAuth, :mount_current_user}] do
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end
end
