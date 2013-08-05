require "uri"
require "restful_geof/routes"

module RestfulGeof
  module Controller

    def self.handle(request)

      Routes.route(request)

    end

  end
end

