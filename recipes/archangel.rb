Capistrano::Configuration.instance(:must_exist).load do
  set(:archangel_command)           { "/usr/bin/env archangel" }
  
  set(:archangel_timestamp)         { set :archangel_timestamped, true; Time.now.utc.strftime("%Y%m%d%H%M%S") }
  set(:archangel_path)              { "#{admin_path}/archangel" }
  set(:archangel_releases_path)     { "#{archangel_path}/releases" }
  set(:archangel_releases)          { capture("ls -x #{archangel_releases_path}").split.sort }
  set(:archangel_release_path)      { File.join(archangel_releases_path, archangel_timestamp) }
  set(:current_archangel_path)      { File.join(archangel_path, "current") }

  set(:current_archangel_release)   { File.join(archangel_releases_path, archangel_releases.last) }
  set(:previous_release)            { File.join(archangel_releases_path, archangel_releases[-2]) }
  set(:latest_archangel_release)    { exists?(:archangel_timestamped) ? archangel_release_path : current_archangel_release }
  set(:archangel_config)            { "#{latest_archangel_release}/sites.archangel" }

  set(:local_archangel_gem_path)    { Gem.searcher.find('archangel').full_gem_path }
  set(:local_archangel_config)      { "#{host_config_path}/sites.archangel" }
  set(:local_archangel_god_config)  { "#{local_archangel_gem_path}/views/archangel.god" }
  set(:archangel_god_config)        { "#{archangel_path}/sites.god" }

  namespace :archangel do
    desc "Setup the environment"
    task :setup do
      run <<-EOT
        mkdir -p #{archangel_path} #{archangel_releases_path} && 
        ln -sf #{current_archangel_path}/sites.archangel #{archangel_path}/sites.archangel
      EOT
      logger.debug "Uploading #{local_archangel_god_config}"
      put File.read(local_archangel_god_config), archangel_god_config
      god.setup
      nginx.setup
    end
  
    desc "Update the server"
    task :update do
      upload
      symlink
      god.restart
      nginx.update
    end
  
    desc "Upload the latest configuration"
    task :upload do
      run "mkdir -p #{archangel_release_path}"
      put File.read(local_archangel_config), archangel_config
    end
    
    task :symlink do
      on_rollback { run "rm -f #{current_archangel_path}; ln -s #{previous_archangel_release} #{current_archangel_path}; true" }
      run <<-EOT
        rm -f #{current_archangel_path} && 
        ln -s #{latest_archangel_release} #{current_archangel_path}
      EOT
    end
    
    def build(name, path)
      run "mkdir -p #{path} && cd #{path} && #{archangel_command} -c #{archangel_config} -t #{name} build"
    end
  end
end