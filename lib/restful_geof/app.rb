require "sinatra/base"
require "restful_geof/routes"

module RestfulGeof
  class App < Sinatra::Base
    post(//) { Routes.route(request) }
    get(//) { Routes.route(request) }
    put(//) { Routes.route(request) }
    delete(//) { Routes.route(request) }
    run! if app_file == $0 # start the server if this file is executed directly
  end
end
