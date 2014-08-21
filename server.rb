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

def post_is_valid?(post_title, post_url, post_description)

  if post_title == nil
    return false

  elsif post_url !~ (/^(www)\.\w+\..{2,6}$/)
    return false

  elsif post_description == nil || post_description.length < 20
    return false
  end
  true

end



########ROUTES############
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
    erb :submit
  end
end


