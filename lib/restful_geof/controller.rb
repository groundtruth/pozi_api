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
      store = Store.new(params[:database], params[:table])
      outcome = store.send(action, params)

      if outcome.okay?
        if outcome.data.empty?
          [204, ""] # HTTP 204 No Content: The server successfully processed the request, but is not returning any content
        else
          [200, outcome.data.to_json]
        end
      else
        if outcome.problem == "Not found"
          [404, {}.to_json]
        else
          [400, { error: outcome.problem }.to_json ]
        end
      end

    end

  end
end

