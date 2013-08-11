require "uri"

require "ruby/object"

module RestfulGeof
  class Routes

    def initialize(request)
      @request_method = request.request_method
      @path_info = request.path_info
      @body = request.body.read
    end

    def match_find_path
      if @path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        (?<conditions_string>(/[^/]+/[^/]+/[^/]+)*)
        (/limit/(?<limit>\d+))?
        $
      }x)
        @matched_database = URI.unescape $~[:database].to_s
        @matched_table = URI.unescape $~[:table].to_s
        @matched_limit = URI.unescape $~[:limit].to_s
        @matched_conditions_raw = $~[:conditions_string].to_s.scan(%r{/(?<part1>[^/]+)/(?<part2>[^/]+)/(?<part3>[^/]+)}x)
        return true
      end
    end

    def crud_request_params
      if crud_action && @path_info.match(%r{
        ^
        /(?<database>[^/]+)
        /(?<table>[^/]+)
        (/(?<id>[^/]+))?
        $
      }x)
        valid_params(
          trim_params({
            :action => crud_action,
            :database => URI.unescape($~[:database].to_s),
            :table => URI.unescape($~[:table].to_s),
            :id => URI.unescape($~[:id].to_s),
            :body_json => @body
          })
        )
      end
    end

    def crud_action
      {
        "GET" => :read,
        "POST" => :create,
        "DELETE" => :delete,
        "PUT" => :update
      }[@request_method]
    end

    def trim_params(params)
      Hash[params.map { |k,v| [k, v] unless v.empty? }.compact]
    end

    def valid_params(params)
      params.keys == {
        :read =>   [:action, :database, :table, :id],
        :create => [:action, :database, :table, :body_json],
        :delete => [:action, :database, :table, :id],
        :update => [:action, :database, :table, :id, :body_json]
      }[crud_action] && params
    end

    def params

      if @request_method == "GET" && match_find_path

        condition_options = { :is => {}, :in => {}, :matches => {}, :contains => {}, :closest => {} }
        condition_options[:limit] = @matched_limit.to_i unless @matched_limit.empty?
        @matched_conditions_raw.each do |condition_raw|
          part1, part2, part3 = condition_raw.map { |str| URI.unescape str }
          if part2.is_in?(%w{is matches contains})
            condition_options[part2.to_sym][part1] = part3
          elsif part2 == "in"
            condition_options[:in][part1] = condition_raw.last.split(",").map { |str| URI.unescape str }
          elsif part1 == "closest"
            condition_options[:closest][:lon] = part2
            condition_options[:closest][:lat] = part3
          else
            return { :action => :unknown }
          end
        end

        return {
          :action => :find,
          :database => @matched_database,
          :table => @matched_table,
          :conditions => condition_options
        }

      elsif crud_request_params
        crud_request_params
      else
        { :action => :unknown }
      end

    end

  end
end

