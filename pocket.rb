require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'link_thumbnailer'
require 'pry'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:bookmarks] ||= []
end

get '/' do
  erb :index
end

post '/' do
  begin
    link = LinkThumbnailer.generate params[:url]
    session[:bookmarks] << link
    redirect '/bookmarks'
  rescue LinkThumbnailer::Exceptions => e
    session[:message] = "This link is broken, please check again"
    redirect '/'
  end
end

get '/bookmarks' do
  @bookmarks = session[:bookmarks]
  erb :bookmarks
end
