ActionController::Routing::Routes.draw do |map|
  map.resources :invitations

  map.signup 'signup', :controller => 'users', :action => 'new'
  map.login 'login', :controller => 'sessions', :action => 'new'
  map.logout 'logout', :controller => 'sessions', :action => 'destroy'
  
  map.imports 'imports', :controller => 'imports'
  map.connect 'imports/vcard', :controller => 'imports', :action => 'create_vcard',
    :conditions => { :method => :post }

  # FIXME: users shouldnt be a resource, we only ever work with current user
  map.connect 'users/edit_person', :controller => 'users', :action => 'edit_person'
  map.connect 'users/log', :controller => 'users', :action => 'log'
  map.resources :users

  # These have to come first, because we generate people as a resource later
  map.connect 'people/show_many', :controller => 'people', :action => 'show_many'
  map.connect 'people/edit_import_merge', :controller => 'people', :action => 'edit_import_merge'
  map.connect 'people/import_merge', :controller => 'people', :action => 'import_merge',
    :conditions => { :method => :post }
  map.connect 'people/destroy_many', :controller => 'people', :action => 'destroy_many',
    :conditions => { :method => :post }

  
  #map.resources :people, :has_many => [:phones, :addresses]
  # this is the same as
  map.resources :people do |person|
    person.resources :phones
    person.resources :addresses
    person.resources :emails
  end
  
  #map.resources :phones
  
  map.resource :session
  map.resources :link_requests

  #map.resources :imports
  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  map.root :controller => "people"
  
  
  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
