require "sinatra"
require "sinatra/reloader"
require "pry"
require "tilt/erubis"

# enable session
configure do
  enable :sessions # activate
  set :session_secret, 'secret'
end

before do
  session[:money] ||= 100
end

def check_result(num_com, num_user, bet_num)
  if num_com == num_user
    session[:message] = "You have guessed correctly"
    session[:money] += bet_num
  else
    session[:message] = "You guessed #{num_user}, but the number is #{num_com}"
    session[:money] -= bet_num
  end
end

# render the guess main page
 
get "/" do
  erb :guess, layout: :layout
end

# replay reset the game
post "/" do
  session[:money] = 100
  redirect "/"
end

get "/broke" do
  "You are broke"
end

# check if the number is correct
post "/check_result" do
  @num_gen = rand(1..3)

  bet_money = params[:bet].to_i
  button_num = params[:guess].to_i
# check if input valid

  if bet_money < 1 || bet_money > session[:money]
    session[:message] = "Bets must be between $1 and $#{session[:money]}"
    erb :guess, layout: :layout
  else
    check_result(@num_gen, button_num, bet_money)
    if session[:money] <= 0
      redirect "/broke"
    end
    redirect "/"
  end
   
end

get "/test" do
  erb :guess
  redirect "/" #halt
 
end
