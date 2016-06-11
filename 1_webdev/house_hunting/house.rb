require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "pry"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @question_list = YAML.load_file("question.yaml")
  @property_list = YAML.load_file("property.yaml")
  session[:input] ||= {}
  session[:id] ||= 1
  
  if !@question_list
    @question_list["test"] = {}
  end
end

get "/" do
 
  erb :question, layout: :layout
end


post "/" do
  session[:input][session[:id]] = {}
 
  @property_list.keys.each do |p|
    session[:input][session[:id]][p] = params[p.to_sym]
  end
binding.pry
 
  @property_list.keys.each do |p|
    if params[p.to_sym].strip.empty?
      session[:message] = "Please fill in all the information"
      
      redirect "/#{session[:id]}"
    end
  end
  
  @question_list[session[:id]] = session[:input][session[:id]]
  
  File.open("question.yaml", "w") {|file| file.write @question_list.to_yaml }
  
  session[:id] += 1
  
  session[:message] = "The house has been added"
  redirect "/result" 
end

get "/result" do

  erb :result, layout: :layout
end

post "/:id/remove" do
  id = params[:id].to_i
  session[:input].delete(id)
  @question_list.delete(id)
  
  File.open("question.yaml", "w") {|file| file.write @question_list.to_yaml }
  session[:message] = "The house has been removed"
  redirect "/result"
end

get "/:id" do
  binding.pry
  @id = params[:id].to_i
  @keys = session[:input].keys

  erb :edit, layout: :layout
end

post "/:id" do
  @id = params[:id].to_i
  @keys = session[:input].keys
  
  @property_list.keys.each do |p|
    session[:input][@id][p] = params[p.to_sym]
  end
  
  @property_list.keys.each do |p|
    if params[p.to_sym].strip.empty?
      session[:message] = "Please fill in all the information"
      redirect "/#{@id}"
    end
  end
    
  @question_list[@id] = session[:input][@id]
   
  File.open("question.yaml", "w") {|file| file.write @question_list.to_yaml }
  
  session[:message] = "The house has been saved"
  redirect "/result"
end