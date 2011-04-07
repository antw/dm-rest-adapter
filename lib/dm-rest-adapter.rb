require 'cgi'  # for CGI.escape
require 'net/http'
require 'addressable/uri'

require 'dm-core'
require 'dm-serializer'

require 'dm-rest-adapter/adapter'
require 'dm-rest-adapter/connection'
require 'dm-rest-adapter/exceptions'

# @todo
#   Since each format is likely to have their own dependencies (yajl, json,
#   yaml, etc), these should probably be auto-loaded.

# require 'dm-rest-adapter/formats/json' # Soon!
require 'dm-rest-adapter/formats/xml'
# require 'dm-rest-adapter/formats/yaml' # Soon! Perhaps. :)

DataMapper::Adapters::RestAdapter = DataMapperRest::Adapter
