require "sinatra/base"
require "restful_geof/controller"

module RestfulGeof
  class App < Sinatra::Base
    configure do
      set :raise_errors, true
      set :show_exceptions, false
    end

    def cors_headers
      if ENV["RESTFUL_GEOF_OPEN_CORS"] == 'true'
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept"
        response.headers["Access-Control-Allow-Methods"] = "POST"
      end
    end

    post(//) { cors_headers; Controller.handle(request) }
    get(//) { cors_headers; Controller.handle(request) }
    put(//) { cors_headers; Controller.handle(request) }
    delete(//) { cors_headers; Controller.handle(request) }
    options(//) { cors_headers; 204 }

    run! if app_file == $0 # start the server if this file is executed directly
  end
end

