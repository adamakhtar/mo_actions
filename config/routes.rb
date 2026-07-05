MoActions::Engine.routes.draw do
  root "actions#index"

  resources :actions, only: :index
  resources :executions, only: [:create, :show, :edit, :update, :destroy] do
    resource :preflight, only: :create
  end
end
