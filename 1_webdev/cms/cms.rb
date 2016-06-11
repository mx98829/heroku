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



def path(source)
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/#{source}", __FILE__)
  else
    File.expand_path("../#{source}", __FILE__)
  end
end

def data_path
  path("data")
end

def history_path
  path("history")
end

def image_path
  path("image_source")
end
  
helpers do
  def load_users_file
    if ENV["RACK_ENV"] == "test"
      YAML.load_file("test/users.yaml")
    else
      YAML.load_file("users.yaml")
    end
  end
  
  def add_user_to_file(username, password)
    if ENV["RACK_ENV"] == "test"
      users = YAML.load_file("test/users.yaml")
    else
      users = YAML.load_file("users.yaml")
    end
    users[username] = password
    
    if ENV["RACK_ENV"] == "test"
      File.open("test/users.yaml", 'w') {|f| f.write users.to_yaml } #Store
    else
      File.open("users.yaml", 'w') {|f| f.write users.to_yaml } #Store
    end
    
    
  end

  def  load_file_names(file_path)
    Dir.glob(File.join(file_path, "*")).map { |path| File.basename(path)}
  end
  
  def get_file_path(name)
    File.join(data_path, name)
    # root + "/#{data_path}/#{name}"
  end
  
  def get_history_dir_path(filename)
    File.join(history_path, filename)
  end
  
  def get_history_file_path(filename, history_file_name)
    File.join(history_path, filename, history_file_name)
  end
  
  def get_image_file_path(filename) 
    File.join(image_path, filename)
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
  
  def load_hisotry_file_content(file, history_file_name)
    history_file_path = get_history_file_path(file, history_file_name)
    content = File.read(history_file_path)
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
    load_users_file.has_key?(username) && 
    
    BCrypt::Password.new(load_users_file[username]) == password
    # BCrypt::Password.create(password_typed) == @user[username]
  end
  
  # def user_valid?(username, password)
  #   if load_users_file.key?(username)
  #     bcrypt_password = BCrypt::Password.new(load_users_file[username])
  #     bcrypt_password == password
  #   else
  #     false
  #   end
  # end
  def put_char_on_text_name(textname, char)
    arr = textname.split(".")
    arr.first << char
    arr.join(".")
  end
  
  def put_number_on_text_name(textname, char = "_1")
    put_char_on_text_name(textname, char)
  end
  
  def put_dup_on_text_name(textname, char = "_dup")
    put_number_on_text_name(textname, char)
  end
  
  def increment_file_number(textname)
    arr = textname.split(".")
    arr.map! {|x| x.split("_") }
    num = arr.first.last.to_i + 1
    arr.first[-1] = num.to_s
 
    arr.map {|x| x.join("_")}.join(".")
  end
end

# def render_index
#   erb :index, layout: :layout
# end


# get "/test" do
#   @name = load_file_names(data_path)
#   render_index
# end

# index page
get "/" do
  # if session[:user].empty?
  #   redirect "/users/signin"
  # else
    @name = load_file_names(data_path)
    erb :index, layout: :layout
  # end
end
##################################################################################
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
    username = params[:username]
    bcrypt_password = BCrypt::Password.create(params[:password])
    add_user_to_file(username, bcrypt_password)
     
    redirect "/users/signin"
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

##################################################################################
# sign out
post "/users/signout" do
  session[:user] = nil
  session[:success] = "You have been successfully signed out"
  redirect "/users/signin"
end


# upload image
get "/upload_image" do
  ensure_sign_in
  @list_of_images = load_file_names(image_path)
   
  erb :upload_image, layout: :layout
end

# upload image confirm
post "/image_upload_confirm" do
  file_name = params[:filename]
  file_path = get_file_path(file_name)
  from_file_path = get_image_file_path(file_name)
  FileUtils.cp(from_file_path, file_path)
  
  # history
  history_dir_path = get_history_dir_path(file_name)
  Dir.mkdir(history_dir_path) if !Dir.exist?(history_dir_path)
  
  new_history_file_name = put_number_on_text_name(file_name)
  history_file_path =  get_history_file_path(file_name, new_history_file_name)
  FileUtils.cp(get_file_path(file_name),  history_file_path )
  
  redirect "/"
end

# render the edit form
get "/:name/edit" do
  ensure_sign_in
  @text_name = params[:name]
  file_path = get_file_path(@text_name)
  @content = File.read(file_path)
  erb :edit_text, layout: :layout
end

# file history page
get "/:name/history" do
  @file_name = params[:name]
  history_file_path = get_history_dir_path(@file_name)
  @history_files =  load_file_names(history_file_path)
  
  
  erb :history, layout: :layout
end

# history file content
get "/:name/:history_name" do
 
  @file_name = params[:name]
  @history_file_name = params[:history_name]
   
  load_hisotry_file_content(@file_name, @history_file_name)
end


# render the new document form
get "/new" do
  ensure_sign_in
  erb :new_text, layout: :layout
end

# add a new text name
post "/new" do
  ensure_sign_in
  @name = load_file_names(data_path)
  text_name = params[:text_name].to_s
   
  if text_name.empty?
    session[:error] = "A name is required."
    status 422
    erb :new_text, layout: :layout
  elsif File.extname(text_name).empty?
    session[:error] = "A file extention is required."
    status 422
    erb :new_text, layout: :layout
  elsif @name.include?(text_name)
    session[:error] = "The file name exists. Please put a different file name"
    status 422
    erb :new_text, layout: :layout
  
  else
    File.new(get_file_path(text_name),  "w+")
    # File.write(file_path, "")
    # history
    history_dir_path = get_history_dir_path(text_name)
    Dir.mkdir(history_dir_path) if Dir.exist?(history_dir_path)
 
    # history_file_path = File.join( history_dir_path, "/#{text_name}_1" )
    # File.new(history_file_path,  "w+")
    
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



# edit the text 
post "/:name" do
   
  text_name = params[:name]
  new_content = params[:text_content]
    
  # if new_content == old_content
  #   session[:error] = "Please make sure you make some changes before hitting save."
  #   erb :edit_text, layout: :layout
  # else
  
  
  # File.open(get_file_path(text_name), 'w') do |f|
  #   f.write new_content
  # end
  
    File.write(get_file_path(text_name), new_content)
    
    #history
     
     # history path has any _1 file, then increment
     
     
    all_history_files_of_one = load_file_names(get_history_dir_path(text_name))
    if all_history_files_of_one.any? {|file| file.include?("_1.")}
      
      last_editted_file = all_history_files_of_one.last
       
      new_text_name = increment_file_number(last_editted_file)
    else # create a 1 file
      # put 1 at the end
      new_text_name = put_number_on_text_name (text_name)
      
    end
    
    history_file_path =  get_history_file_path(text_name, new_text_name)
    FileUtils.cp(get_file_path(text_name),  history_file_path )
  
    session[:success] = "#{text_name} has been editted."
    redirect "/"
  # end
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


# duplicate the file
post "/:name/duplicate" do
  text_name = params[:name]

  file_path = get_file_path(text_name)
  new_text_name = put_dup_on_text_name(text_name)
  new_file_path = get_file_path(new_text_name)
  
  FileUtils.cp(file_path, new_file_path)
  
  # history
  history_dir_path = get_history_dir_path(new_text_name)
  Dir.mkdir(history_dir_path) if !Dir.exist?(history_dir_path)

  new_history_file_name = put_number_on_text_name(new_text_name)
  history_file_path =  get_history_file_path(new_text_name, new_history_file_name)
  
  
  FileUtils.cp(get_file_path(text_name),  history_file_path )
  
  session[:success] = "#{text_name} has been duplicated"
  redirect "/"
end

