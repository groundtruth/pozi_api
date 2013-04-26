require "pozi_api/store"

module PoziAPI
  module Routes

    PREFIX = "/api"

    def self.route(request)
      v = request.request_method
      p = request.path_info

      if v=="GET" && p.match(%r|^#{PREFIX}/(?<database>\w+)/(?<table>\w+)$|)
        return Store.new($~[:database], $~[:table]).read()
      end

      400 # Bad Request
    end

  end
end

