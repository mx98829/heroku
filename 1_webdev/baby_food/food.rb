require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "date"
require "yaml"
require "bcrypt"

configure do 
  enable :sessions
  set :session_secret, 'secret' 
end

before do
  @week =  {1 => "Monday", 
            2 => "Tuesday",
            3 => "Wednesday",
            4 => "Thursday",
            5 => "Friday",
            6 => "Saturday",
            0 => "Sunday"}
            
  @ids ||=[]
  @food = YAML.load_file("food.yaml")
  @users = YAML.load_file("users.yaml")
  @ids = YAML.load_file("ids.yaml")
end

helpers do
  
  def get_monday_date(id)
    date = Date.today
    date + (1-date.wday) + (7 * id)
  end
  
  def today_id
    date = Date.today
    ((date + (1-date.wday) - get_monday_date(0)) / 7).to_i
  end
  
  def sign_in?
    session.key?(:user)
  end
  
  def ensure_sign_in
    unless sign_in?
      session[:message] = "You must sign in to do that."
      redirect "/signin"
    end
  end
  
end

get "/" do

  if !@food[0]
    redirect "/setup"    
  else
    redirect "/overview"
  end
end

# get "/setup" do
#   erb :setup, layout: :layout  
# end

# post "/setup" do
#   @food[0] = {}
#   File.open("food.yaml", "w") {|file| file.write @food.to_yaml }
#   redirect "/question/0"
# end

get "/signin" do
  erb :signin, layout: :layout
end

post "/signin" do
  username = params[:username]
  password = params[:password]
  if @users.has_key?(username) && BCrypt::Password.new(@users[username]) == password
    session[:user] = username
    redirect "/overview"
  else
    session[:message] = "Sign in is failed"
    erb :signin, layout: :layout
  end
end

post "/signout" do
  session.delete(:user)
  session[:message] = "You have been signed out."
  redirect "/signin"
end

get "/overview" do
    
  ensure_sign_in
  
  erb :overview, layout: :layout
end

get "/question/:id" do
 
  ensure_sign_in
  @id = params[:id].to_i
 
  erb :question, layout: :layout  
end
 
post "/question/:id" do
  @id = params[:id].to_i
  if !@week.all? do |num, week|
      params[week.to_sym].empty?
    end
   
    @ids["id"] << @id unless @ids["id"].include?(@id)
    File.open("ids.yaml", "w") {|file| file.write @ids.to_yaml }
    
    @food[@id] = {}
  
    @week.each do |num, week|
      @food[@id][week] = params[week.to_sym]
    end
    
    File.open("food.yaml", "w") {|file| file.write @food.to_yaml }
    session[:message] = "The food has been saved"
  end
  
  
  
  redirect "/question/#{@id}"
end


 