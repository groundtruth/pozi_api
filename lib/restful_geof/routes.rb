require "uri"
require "restful_geof/store"

module RestfulGeof
  module Routes

    def self.route(request)

      if request.request_method == "GET" && request.path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        (?<conditions_string>(/[^/]+/(is|matches|contains)/[^/]+)*)
        (/limit/(?<limit>\d+))?
        $
      }x)

        database = URI.unescape $~[:database].to_s
        table = URI.unescape $~[:table].to_s
        limit = URI.unescape $~[:limit].to_s
        conditions = $~[:conditions_string].to_s.scan(%r{
          /(?<field>[^/]+)
          /(?<operator>is|matches|contains)
          /(?<value>[^/]+)
        }x)

        options = { :is => {}, :matches => {}, :contains => {} }
        options[:limit] = limit.to_i unless limit.empty?
        conditions.each do |condition|
          field, operator, value = condition.map { |str| URI.unescape str }
          options[operator.to_sym][field] = value
        end

        return Store.new(database, table).find(options)

      elsif request.request_method == "GET" && request.path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        /(?<id>[^/]+)
        $
      }x)

        database = URI.unescape $~[:database].to_s
        table = URI.unescape $~[:table].to_s
        id = URI.unescape($~[:id])

        return Store.new(database, table).read(id)

      elsif request.request_method == "POST" && request.path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        $
      }x)

        database = URI.unescape $~[:database].to_s
        table = URI.unescape $~[:table].to_s

        return Store.new(database, table).create(request.body.read)

      elsif request.request_method == "DELETE" && request.path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        /(?<id>[^/]+)
        $
      }x)

        database = URI.unescape $~[:database].to_s
        table = URI.unescape $~[:table].to_s
        id = URI.unescape($~[:id])

        return Store.new(database, table).delete(id)

      elsif request.request_method == "PUT" && request.path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        /(?<id>[^/]+)
        $
      }x)

        database = URI.unescape $~[:database].to_s
        table = URI.unescape $~[:table].to_s
        id = URI.unescape($~[:id])

        return Store.new(database, table).update(id, request.body.read)

      end

      400 # Bad Request
    end

  end
end

