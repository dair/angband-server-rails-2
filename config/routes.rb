Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

    root to: 'reader#games'
    
    post "application/login"

    get "events_j" => "reader#events_j"
    
    
    get "/:id" => "reader#events"

end
