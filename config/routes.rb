Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

    root to: 'reader#games'

    get "login" => "application#login"
    post "do_login" => "application#do_login"

    get "events_j" => "reader#events_j"
    get "objects_j" => "reader#objects_j"
    get "locations_j" => "reader#locations_j"
    
    get "/:id" => "reader#events"
    get "/:id/objects" => "reader#objects"
    get "/:id/locations" => "reader#locations"

end
