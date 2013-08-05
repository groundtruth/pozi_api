require "uri"
require "restful_geof/routes"
require "restful_geof/store"

module RestfulGeof
  module Controller

    def self.handle(request)

      params = Routes.parse(request)

      case params[:action]
      when :find
        Store.new(params[:database], params[:table]).find(params[:options])
      when :read
        Store.new(params[:database], params[:table]).read(params[:options][:id])
      when :create
        Store.new(params[:database], params[:table]).create(params[:options][:json])
      when :delete
        Store.new(params[:database], params[:table]).delete(params[:options][:id])
      when :update
        Store.new(params[:database], params[:table]).update(params[:options][:id], params[:options][:json])
      else
        400 # Bad request
      end

    end

  end
end

