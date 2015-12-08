# encoding: UTF-8
require 'rubygems' if RUBY_VERSION < "1.9"
require 'sinatra/base'
require 'omniauth-oauth2'
require 'omniauth-google-oauth2'
require 'logger'



class Qflight < Sinatra::Base

	configure do
		config = YAML.load_file 'config/credentials.yml'

		set :public_folder, File.dirname(__FILE__) + '/public'
	
		use Rack::Session::Cookie, :key => 'rack.session', :path => '/', :secret => config['SESSION_SECRET']

		use OmniAuth::Builder do
	  	provider :google_oauth2, config['GOOGLE_CLIENT_ID'], config['GOOGLE_CLIENT_SECRET'], {
	      :scope => "email, profile"
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
end