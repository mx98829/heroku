require "tilt/erubis"
require "sinatra"
require "sinatra/reloader"

get "/"  do
  @title = "Dynamic Directory Index"
  @arr = Dir.glob("public/*")
  erb :home
end


get "/welcomefax" do
  @title = "WelcomeFax"
  @contents = File.read("public/welcomefax.txt")

  erb :contents
end


get "/html_codeaca" do
  @title = "html_codeaca"
  @contents = File.read("public/html_codeaca.html")

  erb :contents
end


get "/template" do
  @title = "template"
  @contents = File.read("public/template.html")

  erb :contents
end


get "/?sortorder=a" do
  @title = "Dynamic Directory Index"
  @arr.sort
  erb :home
end


get "/?sortorder=d" do
  @title = "Dynamic Directory Index"
  @arr.reverse
  erb :home
end