Rails.application.routes.draw do
    resources :cats
    get 'cats/index'
  
    # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
    root 'cats#index'
end