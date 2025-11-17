Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # API namespace
  namespace :api do
    namespace :v1 do
      # Authentication
      post "signup", to: "auth#signup"
      post "login", to: "auth#login"
      delete "logout", to: "auth#logout"
      get "me", to: "auth#me"

      # Password Reset
      post "password_resets", to: "password_resets#create"
      put "password_resets/:token", to: "password_resets#update"

      # Dashboard
      get "dashboard", to: "dashboard#index"

      # Swimmers
      resources :swimmers do
        member do
          get "performances/:stroke/:distance_m/:course_type", to: "performances#history", as: :performance_history
          get "future_qualifications"
        end
      end

      # Performances
      post "performances/import", to: "performances#import"

      # Meetings
      resources :meetings do
        member do
          get "status"
          get "review"
          post "confirm"
          get "compare"
          get "swimmer_time_history"
          get "download_pdf"
        end
      end

      # Live Meetings (upcoming swimming events)
      resources :live_meetings, only: [ :index, :show ] do
        collection do
          get "today"
          post "scrape"
          post "refresh"
        end
      end

      # Regions and Counties
      resources :regions, only: [ :index, :show ] do
        member do
          get "counties"
        end
      end

      # Public qualification checker
      post "check_qualification", to: "public#check_qualification"
    end
  end
end
