MoActions::Engine.routes.draw do
  root to: "actions#index"

  post "actions/:key/run", to: "actions#run", as: :run_action
end
