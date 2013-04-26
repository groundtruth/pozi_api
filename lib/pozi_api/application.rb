require "sinatra/base"

module PoziAPI
  class Application < Sinatra::Base

    get "/" do
      puts "got GET"
    end
    
    run! if app_file == $0 # start the server if this file is executed directly
  end
end

