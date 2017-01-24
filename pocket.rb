require 'sinatra'
require 'sinatra/reloader' if development?
require 'erubis'
require 'link_thumbnailer'
require 'psych'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

def bookmark_location
  File.expand_path('../data/bookmarks.yml', __FILE__)
end

def link_existed?(url)
  file = File.read(bookmark_location)
  file.include? url
end

def chop_description(string)
  if string.nil?
    'NO DESCRIPTION'
  else
    string.size > 50 ? string.slice(0, 75) : string
  end
end

def write_to_yaml(link)
  line = [{ title: link.title, url: link.url.to_s,
            description: chop_description(link.description),
            image: image_existed?(link) }]
  path = bookmark_location
  yml = Psych.dump(line)
  File.open(path, 'a+') do |file|
    file.puts(yml[3..-1])
  end
end

def check_link(link)
  if link_existed?(link.url.to_s)
    session[:message] = 'You already add this to your bookmarks'
    redirect '/'
  else
    write_to_yaml(link)
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
  @content = Psych.load_file(bookmark_location) || []
  erb :bookmarks
end

post '/bookmark/:index/delete' do
  @content = Psych.load_file(bookmark_location)

  @content.delete_at params[:index].to_i
  if @content.empty?
    File.write(bookmark_location, "---\n")
    session[:message] = 'There is no more bookmarks'
    redirect '/'
  else
    File.write(bookmark_location, @content.to_yaml)
    session[:message] = 'This bookmark is deleted'
    redirect '/bookmarks'
  end
end

post '/bookmarks/delete/all' do
  File.write(bookmark_location, "---\n")
  session[:message] = 'all bookmarks are deleted!'
  redirect '/'
end
