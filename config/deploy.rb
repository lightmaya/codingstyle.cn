require 'bundler/capistrano'
require 'capistrano/sidekiq'
require 'rvm/capistrano'
require 'capistrano-unicorn'

default_run_options[:pty] = true

set :rvm_ruby_string, 'ruby-2.2.3'
set :rvm_type, :user
set :application, 'codingstyle'
set :repository,  'git://github.com/hkliya/codingstyle.cn.git'
set :branch, 'master'
set :scm, :git
set :user, 'ruby'
set :deploy_to, "/data/www/#{application}"
set :runner, 'ruby'
# set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"

role :web, 'codingstyle.cn'
role :app, 'codingstyle.cn'
role :db,  'codingstyle.cn', primary: true
role :queue, 'codingstyle.cn'

task :link_shared, roles: :web do
  run "mkdir -p #{shared_path}/log"
  run "mkdir -p #{shared_path}/pids"
  run "mkdir -p #{shared_path}/assets"
  run "mkdir -p #{shared_path}/system"
  run "mkdir -p #{shared_path}/cache"
  run "ln -sf #{shared_path}/system #{current_path}/public/system"
  run "ln -sf #{shared_path}/assets #{current_path}/public/assets"
  run "ln -sf #{shared_path}/config/*.yml #{current_path}/config/"
  run "ln -sf #{shared_path}/config/initializers/secret_token.rb #{current_path}/config/initializers"
  run "ln -sf #{shared_path}/pids #{current_path}/tmp/"
  run "ln -sf #{shared_path}/cache #{current_path}/tmp/"
end

task :compile_assets, roles: :web do
  run "cd #{current_path}; RAILS_ENV=production bundle exec rake assets:precompile"
  run "cd #{current_path}; RAILS_ENV=production bundle exec rake assets:cdn"
end

task :migrate_db, roles: :web do
  run "cd #{current_path}; RAILS_ENV=production bundle exec rake db:migrate"
  run "cd #{current_path}; RAILS_ENV=production bundle exec rake db:mongoid:create_indexes"
end

after 'deploy:finalize_update', 'deploy:symlink', :link_shared#, :migrate_db, :compile_assets
after 'deploy:restart', 'unicorn:restart'
