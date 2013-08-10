require "uri"

require "ruby/object"
require "restful_geof/routes"
require "restful_geof/store"

module RestfulGeof
  module Controller

    def self.handle(request)

      params = Routes.parse(request)
      action = params[:action]
      return 400 unless action.is_in?([:find, :read, :create, :delete, :update])
      outcome = nil
      Store.new(params[:database], params[:table]) do |store|
        outcome = store.send(action, params)
      end
      jsonp_wrapper = request[:jsonp] || request[:callback]

      if outcome.okay?
        if outcome.data.empty?
          [204, maybe_wrapped("", jsonp_wrapper)] # HTTP 204 No Content: The server successfully processed the request, but is not returning any content
        else
          [200, maybe_wrapped(outcome.data.to_json, jsonp_wrapper)]
        end
      else
        if outcome.problem == "Not found"
          [404, maybe_wrapped({}.to_json, jsonp_wrapper)]
        else
          [400, maybe_wrapped({ error: outcome.problem }.to_json, jsonp_wrapper) ]
        end
      end

    end

    private

    def self.maybe_wrapped(data, wrapper=nil)
      if wrapper.to_s.empty?
        data
      else
        "#{wrapper}(#{data});"
      end
    end

  end
end

