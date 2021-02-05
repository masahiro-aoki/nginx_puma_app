# config valid for current version and patch releases of Capistrano
lock "~> 3.15"

set :application, "nginx_puma_app"
set :repo_url, "git@github.com:masahiro-aoki/nginx_puma_app.git"
set :branch, ENV['BRANCH'] || "master"
set :deploy_to, '/var/www/rails/nginx_puma_app'

# set :linked_files, fetch(:linked_files, []).push('config/master.key')
set :linked_files, fetch(:linked_files, []).push('config/master.key', 'config/database.yml')
# set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets]
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system')

set :keep_releases, 5
set :rbenv_ruby, '2.7.2'
set :log_level, :debug

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :confirm do
    on roles(:app) do
      puts "This stage is '#{fetch(:stage)}'. Deploying branch is '#{fetch(:branch)}'."
      puts 'Are you sure? [y/n]'
      ask :answer, 'n'
      if fetch(:answer) != 'y'
        puts 'deploy stopped'
        exit
      end
    end
  end

  desc "Initial Deploy"
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc "Restart Application"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end


  desc 'Create database'
  task :db_create do
    on roles(:db) do |host|
      with rails_env: fetch(:rails_env) do
        within current_path do
          execute :bundle, :exec, :rake, 'db:create'
        end
      end
    end
  end

  before :starting, :confirm
  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end
end
