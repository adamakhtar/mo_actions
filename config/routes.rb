MoActions::Engine.routes.draw do
  root "actions#index"

  resources :actions, only: :index
  resources :executions, only: [:create, :edit, :update, :destroy]
end
