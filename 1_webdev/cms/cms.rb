require "sinatra"
require "sinatra/reloader"
require "pry"

configure do 
  enable :sessions #activate
  set :session_secret, 'secret' #set secret the name, every application works after restarting
end

helpers do
    def load_file(name)
        @content = Dir.glob("public/*").find { |name| name == "public/#{name}" }

        return @content if @content
         
        session[:error] = "#{name} does not exist."
      
        redirect "/"
        halt
    end
end


get "/" do
    @name = Dir.glob("public/*")
    erb :layout
end

get "/:name" do
    text_name = params[:name]
    @content = load_file(text_name)
    erb :text
end
 