require "bcrypt"
require "fileutils"
root = File.expand_path( __FILE__)

p root

p File.basename("data/about.md")
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

root = File.expand_path("..", __FILE__)
p File.join(root, "test")

 
p BCrypt::Password.create(123456)
 
# # FileUtils.cp("image_source/image1.md", "data/image1.md")
# # Dir.mkdir(File.join("history/", "fut"))

# p File.join("a", "/b")