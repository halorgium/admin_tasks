Capistrano::Configuration.instance(:must_exist).load do
  HOSTS = Dir.glob("hosts/*/config.rb").inject([]) do |hosts,path|
    dir = File.dirname(path)
    if File.directory?(dir)
      name = File.basename(dir)
      hosts << name
    end
    hosts
  end

  HOSTS.each do |name|
    desc "Set the target hosts to #{name}"
    task(name) do
      set :current_host, name.to_sym
      load "hosts/#{name}/config"
      ENV["HOSTS"] = current_hostname
    end
  end
  
  _cset(:admin_path) { "/home/admin" }
  set(:host_config_path) { "#{local_path}/hosts/#{current_host}" }

  on :start, :except => HOSTS do
    unless exists?(:current_host)
      string = <<-EOT
        You must choose the host to deal with
        Available hosts: #{HOSTS.join(', ')}

        Example: `cap hostname god:status'
      EOT
      indentation = string[/\A\s*/]
      abort string.strip.gsub(/^#{indentation}/, "")
    end
  end
end
