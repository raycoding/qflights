# encoding: UTF-8
require 'rubygems' if RUBY_VERSION < "1.9"
require 'bundler/setup'
require 'sinatra/base'
require 'omniauth-oauth2'
require 'omniauth-google-oauth2'
require 'logger'
require 'json'
require 'open3'
require File.expand_path '../config/app_config.rb', __FILE__
require 'uri'
require 'net/http'

class Qflight < Sinatra::Base

  configure do

    set :public_folder, File.dirname(__FILE__) + '/public'
  
    use Rack::Session::Cookie, :key => 'rack.session', :path => '/', :secret => CONFIG['QFLIGHTS_SESSION_SECRET']

    use OmniAuth::Builder do
      provider :google_oauth2, CONFIG['QFLIGHTS_GOOGLE_CLIENT_ID'], CONFIG['QFLIGHTS_GOOGLE_CLIENT_SECRET'], {
        :scope => "email, profile",
        :access_type => "online"
      }
    end
  end

  helpers do
    def current_user?
      !session[:uid].nil?
    end

    def current_user
      session[:user]
    end

    def remove_empty_keys!(hash)
      hash.each_key do |key|
        if hash[key].is_a? Array
          hash[key].each {|arr| remove_empty_keys!(arr) if arr.is_a? Hash }
        elsif hash[key].is_a? Hash
          remove_empty_keys!(hash[key])
        else
          hash.delete(key) if hash[key].nil? or hash[key] == ""
        end
      end
      hash
    end

    def get_response(res)
      if res.header['Content-Encoding'].eql?('gzip')
        puts "Performing gzip decompression for response body"
        sio = StringIO.new(res.body)
        gz = Zlib::GzipReader.new(sio)
        p = gz.read()
        puts "Finished decompressing response body"
      else
        puts "Page is not compressed"
        p = res.body
      end
      p
    end
  end

  before do
    # we do not want to redirect when the path info starts with /auth/ or /signin or /signout
    skip_if_path = [/^\/auth\//,/^\/signin/,/^\/signout/]
    pass if skip_if_path.select{|e| request.path_info =~ e }.size > 0
    # For /auth/google_oauth2 omniauth will redirect to google for authentication
    redirect to('/signin') unless current_user?
  end

  get '/signin' do
    redirect to ("/") if current_user?
    erb :signin
  end

  get '/signout' do
    session.clear
    redirect to('/signin')
  end

  get '/auth/google_oauth2/callback' do
    content_type 'text/plain'
    auth = request.env['omniauth.auth']
    session[:uid] = auth[:uid]
    session[:user] = auth.extra.raw_info.to_hash.merge(auth.info.to_hash)
    session[:credentials] = auth.credentials.to_hash
    redirect to('/')
  end

  get '/auth/failure' do
    "Error : Could Not Authenticate"
  end

  get '/' do
    erb :index
  end

  get '/profile' do
    @user = session[:user]
    erb :profile
  end

  post '/search' do
    content_type :json
    search_params = params.clone
    remove_empty_keys!(search_params)
    slice = []
    if search_params["journey"]["direction"] == "roundtrip"
      slice << {
        "origin"=>search_params["journey"]["origin"],
        "destination"=>search_params["journey"]["destination"],
        "date"=>search_params["journey"]["date"],
      }
      slice << {
        "origin"=>search_params["journey"]["destination"],
        "destination"=>search_params["journey"]["origin"],
        "date"=>search_params["journey"]["r_date"],
      }
    elsif search_params["journey"]["direction"] == "oneway"
      slice << {
        "origin"=>search_params["journey"]["origin"],
        "destination"=>search_params["journey"]["destination"],
        "date"=>search_params["journey"]["date"],
      }
    end

    request = {
      "request"=>{
        "passengers" => search_params["passengers"],
        "slice" => slice
      }
    }
    page = nil
    uri = URI("#{CONFIG['GOOGLE_API_HOST']}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new("#{CONFIG['QFLIGHTS_API_PATH']}?key=#{CONFIG['QFLIGHTS_API_KEY']}",{'Content-Type' =>'application/json','Accept-Encoding' => 'gzip', 'User-Agent' => 'gzip'})
    req.body = request.to_json
    res = http.request(req)
    case res
      when Net::HTTPSuccess then
        begin
          page = get_response(res)
        rescue => e
          halt 500 ,"#{e.to_s}"
        end
      else
        page = get_response(res)
    end
    page
  end
end