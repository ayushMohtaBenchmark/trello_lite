Rails.application.routes.draw do
  # Liveness probe for load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  # Swagger UI + raw OpenAPI document (served by the rswag engines).
  mount Rswag::Ui::Engine  => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      # --- Authentication --------------------------------------------------
      post   "auth/register", to: "auth#register"
      post   "auth/login",    to: "auth#login"
      post   "auth/refresh",  to: "auth#refresh"
      delete "auth/logout",   to: "auth#logout"
      get    "auth/me",       to: "auth#me"

      # --- Boards and nested configuration ---------------------------------
      resources :boards do
        resources :memberships, controller: :board_memberships,
                                only: %i[index create update destroy]
        resources :labels,     only: %i[index create update destroy]
        resources :webhooks,   only: %i[index create]
        resources :activities, only: %i[index]
        resources :lists,      only: %i[index create]
      end

      # --- Lists (shallow) -------------------------------------------------
      resources :lists, only: %i[show update destroy] do
        resources :cards, only: %i[index create]
      end

      # --- Cards (shallow) -------------------------------------------------
      resources :cards, only: %i[show update destroy] do
        member { patch :move }
        resources :comments,    only: %i[index create]
        resources :attachments, only: %i[index create]
      end

      # --- Shallow leaf resources -----------------------------------------
      resources :comments,    only: %i[update destroy]
      resources :attachments, only: %i[destroy]
      resources :webhooks,    only: %i[show update destroy]
    end
  end
end
