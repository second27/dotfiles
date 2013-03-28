@recipes = %w[root rspec devise cucumber git mongoid factory_girl twitter-bootstrap]

def recipes
  @recipes
end
def recipe?(name)
  @recipes.include?(name)
end
def say_custom(tag, text)
  say "\033[1m\033[36m" + tag.to_s.rjust(10) + "\033[0m" + "  #{text}"
end
def say_recipe(name)
  say "\033[1m\033[36m" + "recipe".rjust(10) + "\033[0m" + "  Running #{name} recipe..."
end
def say_wizard(text)
  say_custom(@current_recipe || 'wizard', text)
end

def ask_wizard(question)
  ask "\033[1m\033[30m\033[46m" + (@current_recipe || "prompt").rjust(10) + "\033[0m\033[36m" + "  #{question}\033[0m"
end
def yes_wizard?(question)
  answer = ask_wizard(question + " \033[33m(y/n)\033[0m")
  case answer.downcase
  when "yes", "y"
    true
  when "no", "n"
    false
  else
    yes_wizard?(question)
  end
end

def no_wizard?(question)
  !yes_wizard?(question)
end

def multiple_choice(question, choices)
  say_custom('question', question)
  values = {}
  choices.each_with_index do |choice,i|
    values[(i + 1).to_s] = choice[1]
    say_custom (i + 1).to_s + ')', choice[0]
  end
  answer = ask_wizard("Enter your selection:") while !values.keys.include?(answer)
  values[answer]
end

@current_recipe = nil
prefs = {:rvmrc=>true}
@configs = {}
config = {}
config['rvmrc'] = yes_wizard?("Create a project-specific rvm gemset and .rvmrc?") if true && true unless config.key?('rvmrc') || prefs.has_key?(:rvmrc)

## RVMRC
if config['rvmrc']
  prefs[:rvmrc] = true
end

if prefs[:rvmrc]
  say_wizard "recipe creating project-specific rvm gemset and .rvmrc"
  # using the rvm Ruby API, see:
  # http://blog.thefrontiergroup.com.au/2010/12/a-brief-introduction-to-the-rvm-ruby-api/
  # https://rvm.io/integration/passenger
  if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
    begin
      gems_path = ENV['MY_RUBY_HOME'].split(/@/)[0].sub(/rubies/,'gems')
      ruby_version = gems_path.split("/").last.gsub("ruby-", "")
      ENV['GEM_PATH'] = "#{gems_path}:#{gems_path}@global"
      require 'rvm'
      RVM.use_from_path! File.dirname(File.dirname(__FILE__))

      say_wizard "creating RVM gemset '#{app_name}'"
      RVM.gemset_create app_name
      run "rvm rvmrc trust"
      say_wizard "switching to gemset '#{app_name}'"
      begin
        RVM.gemset_use! app_name
      rescue StandardError
        raise "rvm failure: unable to use gemset #{app_name}"
      end
      run "rvm gemset list"
      create_file ".rvmrc", "rvm use --create #{ruby_version}@#{app_name}"
    rescue LoadError
      raise "RVM gem is currently unavailable."
    end
  end
end


@after_blocks = []
def after_bundler(&block)
  @after_blocks << [@current_recipe, block]
end

@after_everything_blocks = []
def after_everything(&block)
  @after_everything_blocks << [@current_recipe, block]
end

@before_configs = {}
def before_config(&block)
  @before_configs[@current_recipe] = block
end

def current_recipe=(recipe)
  @current_recipe = recipe
  say_recipe recipe.gsub(/[-_]/, "").capitalzie
end

def ask_wizard_with_default(question, value)
  result = ask_wizard("#{question} [#{value}] ?")
  result.empty? ? value : result
end

############################################################
# Bundle Config
############################################################
# current_recipe = "bundle_config"
# create_file  ".bundle/config", "---\nBUNDLE_PATH: vendor/bundle"

gemset_name = ask_wizard_with_default("What should be gemset name for rvm", "shared")


############################################################
# Devise
############################################################
current_recipe = "devise"

gem 'devise'

after_bundler do
  generate "devise:install"
  generate "devise user"
  unless recipes.include? "mongoid"
    rake "db:create"
    rake "db:migrate"
  end
end

############################################################
# rspec
############################################################
current_recipe = "rspec"

gem 'rspec-rails', '>= 2.10', group: [:test, :development]

gsub_file "config/application.rb", /class Application < Rails::Application.*$/ do |match|
  match << "\n\n"
  match << "    config.generators do |g|\n"
  match << "      g.test_framework :rspec\n"
  match << "    end\n"
end

after_bundler do
  generate 'rspec:install'
  if recipes.include? "mongoid"
    comment_lines "spec/spec_helper.rb", /config.fixture_path/
    comment_lines "spec/spec_helper.rb", /config.use_transactional_fixtures/
  end
  gsub_file "spec/spec_helper.rb", /RSpec.configure do.*$/ do |match|
    match << "\n\n"
    if recipes.include? "mongoid"
      match << "  config.before(:suite) do\n"
      match << "    DatabaseCleaner.orm = :mongoid\n"
      match << "    DatabaseCleaner.strategy = :truncation\n"
      match << "    DatabaseCleaner.clean_with :truncation\n"
      match << "  end\n\n"
      match << "  config.before(:each) do\n"
      match << "    DatabaseCleaner.start\n"
      match << "  end\n\n"
      match << "  config.after(:each) do\n"
      match << "    DatabaseCleaner.clean\n"
      match << "  end\n"
    end
    if recipes.include? "devise"
      match << "\n"
      match << "  config.include Devise::TestHelpers, :type => :controller\n"
    end
    if recipes.include? "factory_girl"
      match << "\n"
      match << "  config.include FactoryGirl::Syntax::Methods\n"
    end
  end
end

############################################################
# cucumber
############################################################
gem 'cucumber-rails',   group: :test, require: false
gem 'database_cleaner', group: :test

after_bundler do
  generate 'cucumber:install'
  if recipes.include? "mongoid"
    gsub_file "features/support/env.rb", "DatabaseCleaner.strategy = :transaction" do |match|
      match = "DatabaseCleaner[:mongoid].strategy = :truncation"
    end
  end
  if recipes.include? "factory_girl"
    append_file "features/support/env.rb", "include FactoryGirl::Syntax::Methods"
  end
end

############################################################
# Monogid
############################################################
current_recipe = "mongoid"

gem 'mongoid'

after_bundler do
  generate "mongoid:config"
end

############################################################
# Factory girl
############################################################
current_recipe = "factory_girl"

gem 'factory_girl_rails', group: :test


############################################################
# Twitter Bootstrap
############################################################
current_recipe = "twitter-bootstrap"

gem 'twitter-bootstrap-rails', group: :assets
gem 'less-rails',              group: :assets
gem 'therubyracer',            group: :assets, :platforms => :ruby

after_bundler do
  generate "bootstrap:install"

  gsub_file "app/views/layouts/application.html.erb", "<body>\n" do |match|
    match << "\n<%= render 'flash', flash: flash %>\n"
  end

  create_file "app/views/application/_flash.html.erb" do
    result = ""
    result.concat '<% flash.each do |name, msg| %>'
    result.concat '  <div class="alert alert-<%= name == :notice ? "success" : "error" %>">'
    result.concat '    <a class="close" data-dismiss="alert">&#215;</a>'
    result.concat '    <div class="container">'
    result.concat '      <%= content_tag :div, msg, :id => "flash_#{name}" if msg.is_a?(String) %>'
    result.concat '    </div>'
    result.concat '  </div>'
    result.concat '<% end %> <!-- flash -->'
    result
  end
end

############################################################
# Root
############################################################
if yes_wizard? "Do you want to generate a root controller?"
  @root_controller = ask_wizard_with_default("What should controller be call", "pages").underscore
  @root_action     = ask_wizard_with_default("What should action be call", "welcome").underscore
end
after_bundler do
  generate :controller, "#{@root_controller} #{@root_action}"
  route "root to: '#{@root_controller}\##{@root_action}'"
  remove_file "public/index.html"
end

############################################################
# Git
############################################################
current_recipe = "git"
@before_configs["git"].call if @before_configs["git"]
say_recipe 'Git'
@configs[@current_recipe] = config

after_everything do
  git :init
  git :add => '.'
  git :commit => '-m "Initial import."'
end


# >-----------------------------[ Run Bundler ]-------------------------------<
@current_recipe = nil
say_wizard "Running Bundler install. This will take a while."

run 'bundle install'
say_wizard "Running after Bundler callbacks."
@after_blocks.each {|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}

@current_recipe = nil
say_wizard "Running after everything callbacks."
@after_everything_blocks.each {|b| config = @configs[b[0]] || {}; @current_recipe = b[0]; b[1].call}
