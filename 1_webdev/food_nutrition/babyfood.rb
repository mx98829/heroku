require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require 'yaml'
require "pry"


configure do 
  enable :sessions #activate
  set :session_secret, 'secret' #set secret the name, every application works after restarting
end

before do 
  @food_list = YAML.load_file("config/food_list.yaml")
  
end

helpers do
  def find_nutrition(food) 
    @food_list.each_with_object([]) do |(nutrition, foods), result|
      result << nutrition if foods.include?(food)
    end.join(", ")
  end
  
  
  def add_food_list(food_name, nutrition_name)
    food_list = YAML.load_file("config/food_list.yaml")
    nutrition_name = nutrition_name
    food_name = food_name.delete(" ")
    
    food_list[nutrition_name] << food_name unless food_list[nutrition_name].include? food_name
    File.open("config/food_list.yaml", "w") {|file| file.write food_list.to_yaml }
  end
  
  def delete_white_space(word)
    word.delete(" ")
  end
end



get "/" do
    
  erb :question
end

get "/food_list" do

  erb :food_list
end

post "/food_list" do
   
  f = params[:food_name].downcase
  n = params[:nutrition_name].downcase
  add_food_list(f, n)
  
  redirect "/food_list"
end


post "/answer" do
  @food = params[:food_name]
  erb :answer
end
 