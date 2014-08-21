require 'csv'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'

def get_articles
  articles = []
  CSV.foreach('articles.csv', headers: true, header_converters: :symbol, converters: :all) do |row|
    articles << row.to_hash
  end
  articles
end

def already_submitted post_url
  articles = []
  CSV.foreach('articles.csv', headers: true, header_converters: :symbol, converters: :all) do |row|
    return true if row[:url] == post_url
  end
  false
end

def post_is_valid?(post_title, post_url, post_description)

  if post_title == ''
    return false

  elsif post_url !~ (/^(www)\.\w+\..{2,6}$/)
    return false

  elsif post_description == nil || post_description.length < 20
    return false
  elsif already_submitted post_url
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
  @articles = get_articles
  erb :index
end

get '/submit' do
  erb :submit
end

post '/submit' do
  if post_is_valid?(params[:post_title], params[:post_url], params[:post_description])
    CSV.open('articles.csv', 'a') do |csv|
      csv << [params[:post_title], params[:post_url], params[:post_description]]
    end
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
    else
      @error = 'This URL has already been posted'
    end
    erb :submit
  end
end


