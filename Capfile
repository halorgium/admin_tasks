def _cset(name, *args, &block)
  unless exists?(name)
    set(name, *args, &block)
  end
end

%w(hosts archangel god nginx).each do |r|
  require "recipes/#{r}.rb"
end

set :user, "admin"
set :local_path, File.expand_path(File.dirname(__FILE__))