Capistrano::Configuration.instance(:must_exist).load do
  set(:nginx_command)           { "/usr/bin/env nginx" }
  
  set(:nginx_timestamp)         { set :nginx_timestamped, true; Time.now.utc.strftime("%Y%m%d%H%M%S") }
  set(:nginx_path)              { "/etc/nginx" }
  set(:nginx_releases_path)     { "#{nginx_path}/releases" }
  set(:nginx_releases)          { capture("ls -x #{nginx_releases_path}").split.sort }
  set(:nginx_release_path)      { File.join(nginx_releases_path, nginx_timestamp) }
  set(:current_nginx_path)      { File.join(nginx_path, "current") }

  set(:current_nginx_release)   { File.join(nginx_releases_path, nginx_releases.last) }
  set(:previous_release)        { File.join(nginx_releases_path, nginx_releases[-2]) }
  set(:latest_nginx_release)    { exists?(:nginx_timestamped) ? nginx_release_path : current_nginx_release }
  
  namespace :nginx do
    task :setup do
      sudo <<-EOT
        sh -c 'mkdir -p #{nginx_path} #{nginx_releases_path} #{nginx_path}/custom && 
          touch #{nginx_path}/custom/blank.conf && 
          chown -R admin #{nginx_path}/releases && 
          ln -sf #{current_nginx_path}/nginx.conf #{nginx_path}/nginx.conf && 
          ln -sf #{current_nginx_path}/servers #{nginx_path}/servers && 
          ln -sf #{current_nginx_path}/upstreams #{nginx_path}/upstreams'
      EOT
    end
    
    task :update do
      run "mkdir -p #{nginx_release_path}"
      build
      symlink
      restart
    end
    
    task :build do
      archangel.build "nginx", latest_nginx_release
    end
    
    task :symlink do
      on_rollback { run "rm -f #{current_nginx_path}; ln -s #{previous_nginx_release} #{current_nginx_path}; true" }
      sudo <<-EOT
        sh -c 'rm -f #{current_nginx_path} && 
          ln -s #{latest_nginx_release} #{current_nginx_path}'
      EOT
      check
    end
    
    task :check do
      sudo "#{nginx_command} -c #{nginx_path}/nginx.conf -t"
    end
    
    task :restart do
      god.restart_watch "nginx"
    end
  end
end
