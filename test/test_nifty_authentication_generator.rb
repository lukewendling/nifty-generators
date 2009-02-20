require File.join(File.dirname(__FILE__), "test_helper.rb")

class TestNiftyAuthenticationGenerator < Test::Unit::TestCase
  include NiftyGenerators::TestHelper
  
  # Some generator-related assertions:
  #   assert_generated_file(name, &block) # block passed the file contents
  #   assert_directory_exists(name)
  #   assert_generated_class(name, &block)
  #   assert_generated_module(name, &block)
  #   assert_generated_test_for(name, &block)
  # The assert_generated_(class|module|test_for) &block is passed the body of the class/module within the file
  #   assert_has_method(body, *methods) # check that the body has a list of methods (methods with parentheses not supported yet)
  #
  # Other helper methods are:
  #   app_root_files - put this in teardown to show files generated by the test method (e.g. p app_root_files)
  #   bare_setup - place this in setup method to create the APP_ROOT folder for each test
  #   bare_teardown - place this in teardown method to destroy the TMP_ROOT or APP_ROOT folder after each test
  context "" do # empty context so we can use setup block
    setup do
      Dir.mkdir("#{RAILS_ROOT}/config") unless File.exists?("#{RAILS_ROOT}/config")
      File.open("#{RAILS_ROOT}/config/routes.rb", 'w') do |f|
        f.puts "ActionController::Routing::Routes.draw do |map|\n\nend"
      end
      Dir.mkdir("#{RAILS_ROOT}/app") unless File.exists?("#{RAILS_ROOT}/app")
      Dir.mkdir("#{RAILS_ROOT}/app/controllers") unless File.exists?("#{RAILS_ROOT}/app/controllers")
      File.open("#{RAILS_ROOT}/app/controllers/application.rb", 'w') do |f|
        f.puts "class Application < ActionController::Base\n\nend"
      end
    end
  
    teardown do
      FileUtils.rm_rf "#{RAILS_ROOT}/config"
      FileUtils.rm_rf "#{RAILS_ROOT}/app"
    end

    context "generator without arguments" do
      rails_generator :nifty_authentication
      should_generate_file 'app/models/user.rb'
      should_generate_file 'app/controllers/users_controller.rb'
      should_generate_file 'app/helpers/users_helper.rb'
      should_generate_file 'app/views/users/new.html.erb'
      should_generate_file 'app/controllers/sessions_controller.rb'
      should_generate_file 'app/helpers/sessions_helper.rb'
      should_generate_file 'app/views/sessions/new.html.erb'
      should_generate_file 'lib/authentication.rb'
      should_generate_file 'test/fixtures/users.yml'
      should_generate_file 'test/unit/user_test.rb'
      should_generate_file 'test/functional/users_controller_test.rb'
      should_generate_file 'test/functional/sessions_controller_test.rb'
    
      should "generate migration file" do
        assert !Dir.glob("#{RAILS_ROOT}/db/migrate/*.rb").empty?
      end
    
      should "generate routes" do
        assert_generated_file "config/routes.rb" do |body|
          assert_match "map.resources :sessions", body
          assert_match "map.resources :users", body
          assert_match "map.login 'login', :controller => 'sessions', :action => 'new'", body
          assert_match "map.logout 'logout', :controller => 'sessions', :action => 'destroy'", body
          assert_match "map.signup 'signup', :controller => 'users', :action => 'new'", body
        end
      end
    
      should "include Authentication" do
        application_controller_name = Rails.version >= '2.3.0' ? 'application_controller' : 'application'
        assert_generated_file "app/controllers/#{application_controller_name}.rb" do |body|
          assert_match "include Authentication", body
        end
      end
    end

    context "generator with user and session names" do
      rails_generator :nifty_authentication, "Account", "CurrentSessions"
      should_generate_file 'app/models/account.rb'
      should_generate_file 'app/controllers/accounts_controller.rb'
      should_generate_file 'app/helpers/accounts_helper.rb'
      should_generate_file 'app/views/accounts/new.html.erb'
      should_generate_file 'app/controllers/current_sessions_controller.rb'
      should_generate_file 'app/helpers/current_sessions_helper.rb'
      should_generate_file 'app/views/current_sessions/new.html.erb'
      should_generate_file 'test/fixtures/accounts.yml'
      should_generate_file 'test/unit/account_test.rb'
      should_generate_file 'test/functional/accounts_controller_test.rb'
      should_generate_file 'test/functional/current_sessions_controller_test.rb'
      
      should "generate routes" do
        assert_generated_file "config/routes.rb" do |body|
          assert_match "map.resources :current_sessions", body
          assert_match "map.resources :accounts", body
          assert_match "map.login 'login', :controller => 'current_sessions', :action => 'new'", body
          assert_match "map.logout 'logout', :controller => 'current_sessions', :action => 'destroy'", body
          assert_match "map.signup 'signup', :controller => 'accounts', :action => 'new'", body
        end
      end
    end
    
    context "generator with shoulda option" do
      rails_generator :nifty_authentication, :test_framework => :shoulda
      
      should "have controller and model tests using shoulda syntax" do
        assert_generated_file "test/functional/users_controller_test.rb" do |body|
          assert_match " should ", body
        end
        assert_generated_file "test/functional/sessions_controller_test.rb" do |body|
          assert_match " should ", body
        end
        
        assert_generated_file "test/unit/user_test.rb" do |body|
          assert_match " should ", body
        end
      end
    end
    
    context "generator with rspec option" do
      rails_generator :nifty_authentication, :test_framework => :rspec
      should_generate_file 'spec/fixtures/users.yml'
    end
    
    context "with spec dir" do
      setup do
        Dir.mkdir("#{RAILS_ROOT}/spec") unless File.exists?("#{RAILS_ROOT}/spec")
      end
    
      teardown do
        FileUtils.rm_rf "#{RAILS_ROOT}/spec"
      end
      
      context "generator without arguments" do
        rails_generator :nifty_authentication
        should_generate_file 'spec/fixtures/users.yml'
        should_generate_file 'spec/models/user_spec.rb'
        should_generate_file 'spec/controllers/users_controller_spec.rb'
        should_generate_file 'spec/controllers/sessions_controller_spec.rb'
      end
      
      context "generator with user and session names" do
        rails_generator :nifty_authentication, "Account", "CurrentSessions"
        should_generate_file 'spec/fixtures/accounts.yml'
        should_generate_file 'spec/models/account_spec.rb'
        should_generate_file 'spec/controllers/accounts_controller_spec.rb'
        should_generate_file 'spec/controllers/current_sessions_controller_spec.rb'
      end
      
      context "generator with testunit option" do
        rails_generator :nifty_authentication, :test_framework => :testunit
        should_generate_file 'test/fixtures/users.yml'
      end
    end
    
    context "generator with haml option" do
      rails_generator :nifty_authentication, :haml => true
      
      should_generate_file "app/views/users/new.html.haml"
      should_generate_file "app/views/sessions/new.html.haml"
    end
  end
end
