require "spec_helper"
require "restful_geof/app"

module RestfulGeof
  describe App do
    include Rack::Test::Methods
    let(:app) { App }

    %w{POST GET PUT DELETE}.each do |verb|
      it "should delegate #{verb} requests to the router" do
        Routes.should_receive(:route)
        self.send verb.downcase, "/some/path"
      end
    end

  end
end

