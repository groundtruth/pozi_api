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

      # if v=="GET" && p.match(%r|^/(?<database>\w+)/(?<table>\w+)(?<conditions>(/[\w +%]+/[\w +%]+/[\w +%]+)*)((?:/limit/)(?<limit>\d+))?$|)
      #   conditions = {}
      #   $~[:conditions][1..-1].to_s.split("/").each_slice(3) do |field, condition, value|
      #     conditions[condition] ||= {}
      #     conditions[condition][field] = value
      #   end
      #   return Store.new($~[:database], $~[:table]).read(conditions)
      # end

      400 # Bad Request
    end

  end
end

