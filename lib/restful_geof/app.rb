require "sinatra/base"
require "restful_geof/controller"

module RestfulGeof
  class App < Sinatra::Base
    configure do
      set :raise_errors, true
      set :show_exceptions, false
    end
    post(//) { Controller.handle(request) }
    get(//) { Controller.handle(request) }
    put(//) { Controller.handle(request) }
    delete(//) { Controller.handle(request) }

    options(//) {
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept"
      response.headers["Access-Control-Allow-Methods"] = "POST"
      204
    } if ENV["RESTFUL_GEOF_OPEN_CORS"] == 'true'

    run! if app_file == $0 # start the server if this file is executed directly
  end
end

