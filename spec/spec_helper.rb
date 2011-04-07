require 'rubygems'
require 'pathname'
require 'webmock/rspec'
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

Spec::Runner.configure do |config|
  config.extend  DataMapperRest::Spec::FormatHelpers
  config.include DataMapperRest::Spec::FormatHelpers
  config.include DataMapperRest::Spec::WebmockHelpers

  # No real connections.
  config.before(:suite) { WebMock.disable_net_connect! }

  # Wipe the memory adapter prior to each example.
  config.after(:each) { DataMapper.repository(:memory).adapter.reset }
end

# Make with_formats available at the top level.
include DataMapperRest::Spec::FormatHelpers
