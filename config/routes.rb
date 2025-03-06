require "sidekiq/web"

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "forecasts#index"

  # Forecast routes
  get "forecast", to: "forecasts#show"
  resources :forecasts, only: [ :index, :create, :show ]

  # Sidekiq Web UI
  if Rails.env.production?
    # Secure Sidekiq in production with basic auth
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      # Replace with a secure authentication check
      ActiveSupport::SecurityUtils.secure_compare(username, ENV["SIDEKIQ_USERNAME"]) &&
      ActiveSupport::SecurityUtils.secure_compare(password, ENV["SIDEKIQ_PASSWORD"])
    end
  end

  # Mount Sidekiq Web UI
  mount Sidekiq::Web => "/sidekiq"
end
