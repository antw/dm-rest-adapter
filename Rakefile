require 'rubygems'
require 'rake'

begin
  gem 'jeweler', '~> 1.5.2'
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name        = 'dm-rest-adapter'
    gem.summary     = 'REST Adapter for DataMapper'
    gem.description = gem.summary
    gem.email       = [ 'hi@antw.me', 'scott.burton [a] joyent [d] com' ]
    gem.homepage    = 'http://github.com/datamapper/%s' % gem.name
    gem.authors     = [ 'Anthony Williams', 'Scott Burton @ Joyent Inc' ]
    gem.has_rdoc    = 'yard'

    gem.rubyforge_project = 'datamapper'
  end

  Jeweler::GemcutterTasks.new

  FileList['tasks/**/*.rake'].each { |task| import task }
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler -v 1.5.2'
end
