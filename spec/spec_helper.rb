require 'rubygems'
require 'pathname'
require 'fakeweb'
require 'dm-validations'
require 'dm-serializer'
require 'dm-sweatshop'

# Support running specs with 'rake spec' and 'spec'
$LOAD_PATH.unshift('lib') unless $LOAD_PATH.include?('lib')

require 'dm-rest-adapter'

ROOT = Pathname(__FILE__).dirname.parent

DataMapper.setup(:default, 'rest://admin:secret@localhost:4000/?format=xml')
DataMapper.setup(:memory,  'in_memory://localhost')

# Must come first...
Pathname.glob((ROOT + 'spec/fixtures/**/*.rb').to_s).each { |file| require file }

Pathname.glob((ROOT + 'spec/factories/**/*.rb').to_s).each  { |file| require file }
Pathname.glob((ROOT + 'spec/support/**/*.rb').to_s).each  { |file| require file }

FakeWeb.allow_net_connect = false

Spec::Runner.configure do |config|
  config.include DataMapperRest::Spec::FakeWebHelpers

  # Wipe the memory adapter prior to each example.
  config.after(:each) { DataMapper.repository(:memory).adapter.reset }

  # Reset FakeWeb.
  config.after(:each) { FakeWeb.clean_registry }
end
