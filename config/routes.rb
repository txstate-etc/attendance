Attendance::Application.routes.draw do
  resources :attendancetypes

  resources :meetings, only: [:show, :edit, :update, :destroy] do
    member do
      post 'record_attendance'
      post 'code'
    end
  end

  resources :sites, only: [:show, :index] do
    resources :sections, only: [] do
      member do
        get 'last_dates', :defaults => {:format => 'json'}
      end
    end
    member do
      post 'update_perms'
      get 'edit_perms'
      post 'update_settings'
      get 'edit_settings'
      post 'update_checkin_settings'
      get 'edit_checkin_settings'
    end
  end

  resources :sections do
    resources :meetings, only: [:new, :create]
    resources :memberships, only: [:show] do
      post 'remove_from_section'
    end
    member do
      post 'record_attendance'
      get 'totals'
      get 'last_dates', :defaults => {:format => 'json'}
    end
  end

  resources :rosterupdate, only: [:index, :create]

  resources :roles

  resources :checkin, only: [:create]
  match '/checkin/code' => 'checkin#code'

  resources :static, :controller => 'pages', :only => [:show]

  match '/lti_tool' => 'launch#index', :via => :post

  match '/login' => 'login#index'
  match '/logout' => 'logout#index'

  match '/rosterupdate/wait' => 'rosterupdate#wait'
  match '/rosterupdate/ready' => 'rosterupdate#ready'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
