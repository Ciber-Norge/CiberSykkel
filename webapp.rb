require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

class CiberSykkel < Sinatra::Application
  enable :sessions

  configure :production do
    set :haml, { :ugly=>true }
    set :clean_trace, true
  end

  configure :development do
    # ...
  end
end

require_relative 'routes/init'
