require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"
require "pry"

configure do 
  enable :sessions #activate
  set :session_secret, 'secret' #set secret the name, every application works after restarting
end

configure do
  set :erb, :escape_html => true
end

helpers do # both accessible in view and rb. if not put in views, dont need to be put here
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end
  
  def list_class(list)
    "complete" if list_complete?(list)
  end
  
  def todos_remaining_count(list)
    # list[:todos].reduce(0) do |sum, todo| 
    #   todo[:completed] ? (sum + 1) : sum 
    # end
    list[:todos].select {|todo| !todo[:completed]}.size
  end
  
  def todos_count(list)
    
     list[:todos].size
  end
  
  def order_list(lists, &block)
    # incomplete_lists = {}
    # complete_lists = {}

     complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }
     
    # lists.each_with_index do |list, index|
    #   if list_complete?(list)
    #     complete_lists[list] = index
    #   else
    #     incomplete_lists[list] = index
    #   end
    # end
    # incomplete_lists.each { |id, list| yield list, id }
    # complete_lists.each { |id, list| yield list, id }
     incomplete_lists.each(&block) #{ |list| yield list, lists.index(list) }
     complete_lists.each(&block) #{ |list| yield list, lists.index(list) }
    # incomplete_lists.each(&block)
    # complete_lists.each(&block)
  end
  
  def order_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }
    incomplete_todos.each(&block) #{ |todo| yield todo, todos.index(todo) }
    complete_todos.each(&block) #{ |todo| yield todo, todos.index(todo) }
    # incomplete_todos= {}
    # complete_todos = {}
    

    # todos.each_with_index do |todo, index|
    #   if todo[:completed]
    #     complete_todos[todo] = index
    #   else
    #     incomplete_todos[todo] = index
    #   end
    # end
    # # incomplete_lists.each { |id, list| yield list, id }
    # # complete_lists.each { |id, list| yield list, id }
    # incomplete_todos.each(&block)
    # complete_todos.each(&block)
    
  end

  def h(content)
    Rack::Utils.escape_html(content)
  end

  def load_list(id)
    list = session[:lists].find{ |l| l[:id] == id }
    return list if list
  
    session[:error] = "The specified list was not found."
    redirect "/lists"

  end
end

before do
  session[:lists] ||= [] # conditional assignment
end

# view all the lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/" do
  redirect "/lists"
end

# Render the new list form
get "/lists/new" do
  # session[:lists] << { name: "New List", todos: []}
  # redirect "/lists"
  erb :new_list, layout: :layout
end

# return an error message if the name is invalid, return nil if name is valid
def error_for_list_name(name)
  if !(1..100).cover? name.size # include is not good
    "The list name must be between 1 and 100 characters."
  elsif session[:lists].any?{|list| list[:name] == name}
    "The list name must be unique."
  end
end

# return an error message if the name is invalid, return nil if name is valid
def error_for_todo_name(todo)
  if !(1..100).cover? todo.size # include is not good
    "The todo name must be between 1 and 100 characters."
  end
end

def next_element_id(elements)
  max = elements.map { |element| element[:id] }.max || 0
  max + 1
end

# create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
     
    id = next_element_id(session[:lists])
    session[:lists] << {id: id, name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end



# view all the todos of a list
get "/lists/:number" do
  
   @list_number = params[:number].to_i
   @list =  load_list(@list_number)
   erb :to_do_list, layout: :layout
end

# edit an existing todo list
get "/lists/:number/edit" do
   number = params[:number].to_i
   @list =  load_list(number)
   erb :edit_list, layout: :layout
end

# update a new list
post "/lists/:number" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  number = params[:number].to_i
  @list =  load_list(number)
  
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{number}"
  end
end

# delete a list
# get '/lists/:number/destroy' do # this is not safe for get request.
#   number = params[:number].to_i
#   session[:lists].delete_at(number)
#   erb :lists, layout: :layout
#   # redirect "/lists"
# end


# delete a list
post '/lists/:number/destroy' do
  number = params[:number].to_i
  session[:lists].reject!{ |list| list[:id] == number }
   if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
    # redirect "/lists"
  else
    session[:success] = "The list has been deleted"
    redirect "/lists"
  end
  
end




# create a todo for a list
post "/lists/:list_number/todo" do
    
    @list_number = params[:list_number].to_i
    todo_name = params[:to_do_name].strip
    @list =  load_list(@list_number)
    error = error_for_todo_name(todo_name)
    if error
        session[:error] = error
    else
        id = next_element_id(@list[:todos])
        @list[:todos] << { id: id, name: todo_name, completed: false }
        session[:success] = "The todo has been added"
       
    end
    erb :to_do_list, layout: :layout
     # instead of redirect
end

# delete a todo from a list
post "/lists/:number/todo/:id/destroy" do
  @list_number = params[:number].to_i
  todo_id = params[:id].to_i
  @list =  load_list(@list_number)
  @list[:todos].reject! { |todo| todo[:id] == todo_id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204 # no content
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_number}"
  end
end

# update the status of a todo
post "/lists/:number/todo/:id" do
  @list_number = params[:number].to_i
  todo_id = params[:id].to_i
  @list =  load_list(@list_number)
  is_completed = params[:completed] == 'true'

  # todo = @list[:todos].find { |todo| todo[:id] == todo_id }
  # todo[:completed] = is_completed
  @list[:todos].each do |todo|
    todo[:completed] = is_completed if todo[:id] == todo_id
  end
  # @list[:todos][index][:completed] = is_completed
 
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_number}"
end

# complete all todos
post "/lists/:number/complete_all" do
  @list_number = params[:number].to_i
  @list =  load_list(@list_number)
  @list[:todos].each {|todo| todo[:completed] = true}
  session[:success] = "All the todos of this list have been completed."
  redirect "/lists/#{@list_number}"
end