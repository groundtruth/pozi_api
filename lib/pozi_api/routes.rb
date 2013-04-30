require "uri"
require "pozi_api/store"

module PoziAPI
  module Routes

    PREFIX = "/api"

    def self.route(request)

      if request.request_method == "GET" && request.path_info.match(%r{
        ^#{Regexp.escape PREFIX}
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        (?<conditions_string>(/[^/]+/(is|matches)/[^/]+)*)
        (/limit/(?<limit>\d+)$)?
      }x)

        database = URI.unescape $~[:database].to_s
        table = URI.unescape $~[:table].to_s
        limit = URI.unescape $~[:limit].to_s
        conditions = $~[:conditions_string].to_s.scan(%r{
          /(?<field>[^/]+)
          /(?<operator>is|matches)
          /(?<value>[^/]+)
        }x)

        options = { :is => {}, :matches => {} }
        options[:limit] = limit.to_i unless limit.empty?
        conditions.each do |condition|
          field, operator = condition[0..1].map { |str| URI.unescape str }
          value = Integer(condition.last) rescue URI.unescape(condition.last)
          options[operator.to_sym][field] = value
        end

        return Store.new(database, table).find(options)
      end

      400 # Bad Request
    end

  end
end

