require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'link_thumbnailer'
require 'redcarpet'
require 'pry'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
end

def convert_markdown(file_content)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file_content)
end

def bookmark_location
  File.expand_path('../data/bookmarks.md', __FILE__)
end

def link_existed?(url)
  file = File.read(bookmark_location)
  content = convert_markdown(file)
  content.include? url
end

def check_link(link)
  if link_existed?(link.url.to_s)
    session[:message] = 'You already add this to your bookmarks'
    redirect '/'
  else
    line = "- [#{link.title}](#{link.url})\n\n#{link.description}\n\n![](#{image_existed?(link)})\n\n "
    path = bookmark_location
    File.open(path, 'a+') do |file|
      file.puts line
    end
    session[:message] = 'This link is added to your bookmarks'
    redirect '/bookmarks'
  end
end

def image_existed?(link)
  link.images.empty? ? '' : link.images.first.src.to_s
end

get '/' do
  erb :index
end

post '/' do
  begin
    link = LinkThumbnailer.generate(params[:url], image_stats: true)
    check_link(link)
  rescue LinkThumbnailer::Exceptions
    session[:message] = 'This link is broken, please check again'
    redirect '/'
  end
end

get '/bookmarks' do
  file = File.read(bookmark_location)
  @content = convert_markdown(file)
  erb :bookmarks
end

post '/bookmarks' do
  File.write(bookmark_location, params[:edit_content])
  session[:message] = 'Your bookmarks has been updated'
  redirect '/bookmarks'
end

# only admin can do it
get '/bookmarks/edit' do
  @content = File.read(bookmark_location)
  erb :edit
end
