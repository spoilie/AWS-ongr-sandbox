include_recipe "deploy"

node[:deploy].each do |application, deploy|
  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  opsworks_deploy do
    app application
    deploy_data deploy
  end
end

execute 'composer install --no-interaction' do
  cwd '/srv/www/ongr_sandbox/current'
  user 'dev'
end

execute 'bundle install' do
  cwd '/srv/www/ongr_sandbox/current'
  not_if 'bundle check'
  user 'dev'
end

execute 'app/console assetic:dump' do
  cwd '/srv/www/ongr_sandbox/current'
  user 'dev'
end

execute "change ownership" do
  command "chown -R web:dev /srv/www/ongr_sandbox"
  user "root"
  action :run
end

execute "fix permissions" do
  command "chmod -R g+wx /srv/www/ongr_sandbox/* && chmod -R g+s /srv/www/ongr_sandbox/"
  user "root"
  action :run
end