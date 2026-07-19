MoActions::Engine.routes.draw do
  root to: "actions#index"

  resources :executions, only: %i[index show new create]
end
