# encoding: UTF-8
require File.expand_path '../qflight.rb', __FILE__
Rack::Handler.default.run(Qflight.new,:Port => 3001)