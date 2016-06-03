ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

  


def create_document(name, content = "")
  File.open(File.join(data_path, name), "w") do |file|
    file.write(content)
  end
end
  
class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
  
  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end
  
  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { user: "kathy" } }
  end
  
  def test_index
    
    create_document "about.md"
    create_document "changes.txt"
    
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"] #Character Encoding
    
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"

  end
  
  def test_document 
    
    create_document "test.txt",  "test"
    get "/test.txt"
    
    
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
     
     
    assert_equal  "test", last_response.body
   
  end

  def test_document_not_found
    get "/xxx"
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal  "xxx does not exist.", session[:error] 
    get last_response["Location"]
    assert_equal 200, last_response.status

   
  end
  
  def test_markdown
    create_document "about.md", "<h1>apple</h1>"
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
     
    # assert_equal "<h1>apple</h1>", last_response.body
  end
  
  def test_edit_page
    create_document "history.txt",  "test"
    get "/history.txt/edit", {}, admin_session
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Edit history.txt"
    assert_includes last_response.body, "test"
  end
  
  def test_edit_page_signed_out
    create_document "history.txt",  "test"
    get "/history.txt/edit"
    assert_equal 302, last_response.status
    
    get last_response["location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "You must sign in"
  end
  
  def test_update_page
    # create_document "history.txt",  File.read("data/history.txt")
    post "/history.txt", {text_content: "new content"}, admin_session
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "history.txt has been editted.", session[:success]
    
    get last_response["Location"]
    # assert_includes last_response.body, "history.txt has been editted"

    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "new content"
  end
  
  
  def test_new_document
    get "/new", {}, admin_session
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Add a new document" 
  end
  
  def test_submit_new_document_success
     post "/new", { text_name: "test.txt" }, admin_session
     assert_equal 302, last_response.status
     
     get last_response["location"]
     assert_equal 200, last_response.status
     assert_includes last_response.body, "test.txt has been created"
  end
  
  def test_submit_new_document_empty
     post "/new", { text_name: "" }, admin_session
     assert_equal 422, last_response.status
     assert_includes last_response.body, "A name is required."
  end
  
  def test_submit_new_document_no_extension
     post "/new", { text_name: "test" }, admin_session
     assert_equal 422, last_response.status
     assert_includes last_response.body, "A file extention is required."
  end
  
  
  def test_delete
    create_document "history.txt" 
    post "/history.txt/destroy", {}, admin_session 
 
    assert_equal 302, last_response.status
    assert_equal "history.txt has been deleted", session[:success]
    
    get last_response["location"]
    assert_equal 200, last_response.status
    # assert_includes last_response.body, "history.txt has been deleted"
    
    get "/"
    refute_includes last_response.body, "history.txt"
  end
  
  def test_sign_in_sucess
   
    get "/users/signin"  
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    
    assert_includes last_response.body, %q(<label for = "password">Password</label>)
    
    post "/users/signin", username: "kathy", password: 123
    assert_equal 302, last_response.status
    assert_equal "Welcome to CMS!", session[:success]
    assert_equal "kathy", session[:user]
    
    get last_response["location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Signed in"
  end
  
  def test_sign_in_fail
    
    post "/users/signin", username: "kathy", password: 1234
    assert_equal 422, last_response.status
    assert_equal nil, session[:user]
  end
  
  def test_sign_out
    post "/users/signout"
    assert_equal 302, last_response.status
    
    get last_response["location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<label for = "username">Username</label>)
  end
  
  def test_duplicate_text
    create_document "history.txt"
    post "/history.txt/duplicate" , admin_session
    assert_equal 302, last_response.status
    
    get last_response["location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(history.txt has been duplicated)
  end
  
  def test_sign_up_form
    get "/users/signup"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Enter your username"
  end
  
  def test_sign_up_check_success
    post "/users/signup_check", password: 123456, password_again: 123456
    assert_equal 302, last_response.status
    
    get last_response["location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<label for = "username">Username</label>)
  end
  
  def test_sign_up_check_fail
    post "/users/signup_check", password: 123456, password_again: 123457
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Password must be at least 6 characters long"
  end
end