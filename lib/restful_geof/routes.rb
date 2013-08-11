require "uri"

require "ruby/object"

module RestfulGeof
  class Routes

    def initialize(request)
      @request_method = request.request_method
      @path_info = request.path_info
      @body = request.body.read
    end

    def params

      if @request_method == "GET" && @path_info.match(%r{
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

        condition_options = { :is => {}, :in => {}, :matches => {}, :contains => {}, :closest => {} }
        condition_options[:limit] = limit.to_i unless limit.empty?
        conditions.each do |condition|
          part1, part2, part3 = condition.map { |str| URI.unescape str }
          if part2.is_in?(%w{is matches contains})
            condition_options[part2.to_sym][part1] = part3
          elsif part2 == "in"
            condition_options[:in][part1] = condition.last.split(",").map { |str| URI.unescape str }
          elsif part1 == "closest"
            condition_options[:closest][:lon] = part2
            condition_options[:closest][:lat] = part3
          else
            return { :action => :unknown }
          end
        end

        return {
          :action => :find,
          :database => database,
          :table => table,
          :conditions => condition_options
        }

      elsif @request_method == "GET" && @path_info.match(%r{
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

      elsif @request_method == "POST" && @path_info.match(%r{
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
          :body_json => @body
        }

      elsif @request_method == "DELETE" && @path_info.match(%r{
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

      elsif @request_method == "PUT" && @path_info.match(%r{
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
          :body_json => @body
        }

      end

      { :action => :unknown }
    end

  end
end

