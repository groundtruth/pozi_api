require "uri"

module RestfulGeof
  module Routes

    def self.parse(request)

      if request.request_method == "GET" && request.path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        (?<conditions_string>(/[^/]+/[^/]+/[^/]+)*)
        (/limit/(?<limit>\d+))?
        $
      }x)

        database = URI.unescape $~[:database].to_s
        table = URI.unescape $~[:table].to_s
        limit = URI.unescape $~[:limit].to_s
        conditions = $~[:conditions_string].to_s.scan(%r{/(?<part1>[^/]+)/(?<part2>[^/]+)/(?<part3>[^/]+)}x)

        condition_options = { :is => {}, :matches => {}, :contains => {}, :closest => {} }
        condition_options[:limit] = limit.to_i unless limit.empty?
        conditions.each do |condition|
          part1, part2, part3 = condition.map { |str| URI.unescape str }
          if %w{is matches contains}.include?(part2)
            condition_options[part2.to_sym][part1] = part3
          elsif part1 == "closest"
            condition_options[:closest][:lon] = part2
            condition_options[:closest][:lat] = part3
          end
        end

        return {
          :action => :find,
          :database => database,
          :table => table,
          :conditions => condition_options
        }

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

        return {
          :action => :read,
          :database => database,
          :table => table,
          :id => id
        }

      elsif request.request_method == "POST" && request.path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        $
      }x)

        database = URI.unescape $~[:database].to_s
        table = URI.unescape $~[:table].to_s

        return {
          :action => :create,
          :database => database,
          :table => table,
          :body_json => request.body.read
        }

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

        return {
          :action => :delete,
          :database => database,
          :table => table,
          :id => id
        }

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

        return {
          :action => :update,
          :database => database,
          :table => table,
          :id => id,
          :body_json => request.body.read
        }

      end

      { :action => :unknown }
    end

  end
end

