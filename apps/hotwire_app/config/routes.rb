Rails.application.routes.draw do
  root "appointments#index"
  resources :appointments

  get "up" => "rails/health#show", as: :rails_health_check
end
