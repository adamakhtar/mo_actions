MoActions::Engine.routes.draw do
  root to: "actions#index"

  resources :executions, only: %i[index new create]
end
