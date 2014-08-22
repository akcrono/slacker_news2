require 'csv'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'redis'
require 'JSON'

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

def find_articles
  redis = get_connection
  serialized_articles = redis.lrange("slacker:articles", 0, -1)

  articles = []

  serialized_articles.each do |article|
    articles << JSON.parse(article, symbolize_names: true)
  end

  articles
end

def save_article(url, title, description)
  article = { url: url, title: title, description: description }

  redis = get_connection
  redis.rpush("slacker:articles", article.to_json)
end

def get_articles
  articles = []
  CSV.foreach('articles.csv', headers: true, header_converters: :symbol, converters: :all) do |row|
    articles << row.to_hash
  end
  articles
end

def already_submitted? post_url
  articles = []
  CSV.foreach('articles.csv', headers: true, header_converters: :symbol, converters: :all) do |row|
    return true if row[:url] == post_url
  end
  false
end

def post_is_valid?(post_title, post_url, post_description)

  if !title_is_valid? post_title
    return false

  elsif !url_is_valid? post_url
    return false

  elsif !description_is_valid? post_description
    return false

  elsif already_submitted? post_url
    return false
  end
  true
end

def title_is_valid? post_title
  if post_title == ''
    return false
  end
  true
end

def url_is_valid? post_url
  if post_url !~ (/^(www)\.\w+\..{2,6}$/)
    return false
  end
  true
end

def description_is_valid? post_description
  if post_description == nil || post_description.length < 20
    return false
  end
  true
end



get '/' do
  @articles = find_articles
  erb :index
end

get '/submit' do
  erb :submit
end

post '/submit' do
  if post_is_valid?(params[:post_title], params[:post_url], params[:post_description])
    save_article(params[:post_url], params[:post_title], params[:post_description])
  redirect '/'
  else
    @error = 'Invalid input'
    @post_title = params[:post_title]
    @post_url = params[:post_url]
    @post_description = params[:post_description]
    if !title_is_valid? @post_title
      @error = 'Invalid title'
    elsif !url_is_valid? @post_url
      @error = 'Invalid url (FORMAT: www.google.com'
    elsif !description_is_valid? @post_description
      @error = 'Description must be at least 20 characters'
    elsif already_submitted? @post_url
      @error = 'This URL has already been posted'
    end
    erb :submit
  end
end


