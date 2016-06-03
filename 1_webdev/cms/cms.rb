require "sinatra"
require "sinatra/reloader"
require "pry"
require "tilt/erubis"
require "redcarpet"
require 'yaml'
require 'bcrypt'
require "fileutils"

configure do 
  enable :sessions #activate
  set :session_secret, 'secret' #set secret the name, every application works after restarting
end

before do
  
  if ENV["RACK_ENV"] == "test"
    @users = YAML.load_file("test/users.yaml")
  else
    @users = YAML.load_file("users.yaml")
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end
  
helpers do
  
  
  
  def  load_file_names
    Dir.glob(File.join(data_path, "*")).map { |path| File.basename(path)}
  end
  
  def get_file_path(name)
    File.join(data_path, name)
    # root + "/#{data_path}/#{name}"
  end
  
  def check_file_exist?(name)
    file_path = get_file_path(name)
     
    return name if File.exist?(file_path)
    # find { |x| x == "data/#{name}" }
    # return @content if @content
     
    session[:error] = "#{name} does not exist."
    redirect "/"
    halt
  end
  
  def markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(text)
  end
  
  def load_file_content(name)
    
    file = check_file_exist?(name)
    file_path = get_file_path(file)
    content = File.read(file_path)
    if File.extname(file) == ".txt"
      headers["Content-Type"] = "text/plain"
      content
    elsif File.extname(file) == ".md"
      markdown(content)
    end
  end
  
  def sign_in?
    # !session[:user].nil?
    session.key?(:user)
  end
  
  def ensure_sign_in
    unless sign_in?
      session[:error] = "You must sign in to do that."
      redirect "/users/signin"
    end
  end
  
  def user_valid? (password, username)
    @users.has_key?(username) && 
    BCrypt::Password.new(@users[username]) == password
    # BCrypt::Password.create(password_typed) == @user[username]
  end
  
  # def user_valid?(username, password)
  #   if @users.key?(username)
  #     bcrypt_password = BCrypt::Password.new(@users[username])
  #     bcrypt_password == password
  #   else
  #     false
  #   end
  # end
  
end

# index page
get "/" do
  # if session[:user].empty?
  #   redirect "/users/signin"
  # else
    @name = load_file_names
    erb :index, layout: :layout
  # end
end

get "/upload_image" do
  
  @list_of_images = Dir.glob("image_source/*").map { |file| File.basename(file)}
   
  erb :upload_image, layout: :layout
end


post "/image_upload_confirm" do
  file_name = params[:filename]
  file_path = get_file_path(file_name)
  from_file_path = File.join("image_source/", file_name)
  FileUtils.cp(from_file_path, file_path)
  redirect "/"
end

# render the new document form
get "/new" do
  ensure_sign_in
  erb :new_text, layout: :layout
end

# add a new text name
post "/new" do
  ensure_sign_in
  @name = load_file_names
  text_name = params[:text_name].to_s
   
  if text_name.empty?
    session[:error] = "A name is required."
    status 422
    erb :new_text, layout: :layout
  elsif File.extname(text_name).empty?
    session[:error] = "A file extention is required."
    status 422
    erb :new_text, layout: :layout
  else
    File.new(get_file_path(text_name),  "w+")
    # File.write(file_path, "")
    session[:success] = "#{text_name} has been created."
    redirect "/"
  end
end

# content page
get "/:name" do
  text_name = params[:name]
  
  
  load_file_content(text_name)
  # erb :text  # dont need to render the template and layout
end

# render the edit form
get "/:name/edit" do
  ensure_sign_in
  @text_name = params[:name]
  file_path = get_file_path(@text_name)
  @content = File.read(file_path)
  erb :edit_text, layout: :layout
end

# edit the text 
post "/:name" do
  
  text_name = params[:name]
  new_content = params[:text_content]
  
  # File.open(get_file_path(text_name), 'w') do |f|
  #   f.write new_content
  # end
 
  File.write(get_file_path(text_name), new_content)
  session[:success] = "#{text_name} has been editted."
  redirect "/"
end



# delete a text name
post "/:name/destroy" do
  ensure_sign_in
  text_name = params[:name]
  File.delete(get_file_path(text_name))
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
     
    status 204 # no content
  else
    session[:success] = "#{text_name} has been deleted"
    redirect "/"
  end
  
end

# render the sign in page
get "/users/signin" do
  erb :sign_in, layout: :layout
end

# sign in check
post "/users/signin" do
  # users = {"admin" => "secret", "kathy" => 123}
   user_name_input = params[:username]
   password_input = params[:password]
   
   
   if user_valid?(password_input, user_name_input)
     
      session[:user] = user_name_input
      session[:success] = "Welcome to CMS!"
      redirect "/"
   else
      session[:error] = "Your username and password are wrong"
      status 422 # The 422 (Unprocessable Entity) status code means the server understands the content 
      erb :sign_in, layout: :layout
   end
end

# sign out
post "/users/signout" do
  session[:user] = nil
  session[:success] = "You have been successfully signed out"
  redirect "/users/signin"
end

# duplicate the file
post "/:name/duplicate" do
  text_name = params[:name]

  file_path = get_file_path(text_name)
  new_file_path = get_file_path(text_name + "dup")
  FileUtils.cp(file_path, new_file_path)
  session[:success] = "#{text_name} has been duplicated"
  redirect "/"
end

# user sign up
get "/users/signup" do 
  erb :sign_up, layout: :layout
end

post "/users/signup_check" do
  if params[:password] != params[:password_again]
     session[:error] = "The passwords you put in are not the same."
     status 422
     erb :sign_up, layout: :layout
  elsif params[:password].length < 6
     session[:error] = "The passwords must be at least 6 characters long."
     status 422
     erb :sign_up, layout: :layout
  elsif params[:username].strip.empty?
     session[:error] = "Please put in a valid username."
     status 422
     erb :sign_up, layout: :layout
  else
     redirect "/users/signin"
  end

end

