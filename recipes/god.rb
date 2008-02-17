Capistrano::Configuration.instance(:must_exist).load do
  set(:god_path) { "#{admin_path}/god"}
  set(:god_config) { "#{god_path}/main.god" }
  set(:custom_god_path) { "#{god_path}/custom" }
  set(:god_command) { "/usr/bin/env god" }
  
  namespace :god do
    task :setup do
      run "mkdir -p #{god_path} #{custom_god_path}"
      require 'erb'
      template = File.read("#{local_path}/templates/main.god.erb")
      result = ERB.new(template).result(binding)
      put result, god_config
    end
    
    task :start do
      sudo "#{god_command} -c #{god_config} -l /var/log/god.log --no-syslog"
    end
    
    task :stop do
      sudo "#{god_command} quit" rescue nil
    end
    
    task :restart do
      stop
      start
    end
    
    task :status do
      output = capture "sudo #{god_command} status"
      puts output
    end
    
    def restart_watch(name)
      sudo "#{god_command} restart #{name}"
    end
  end
end