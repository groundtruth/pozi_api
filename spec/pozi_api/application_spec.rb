require "spec_helper"
require "pozi_api/application"

describe "Application" do
  include Rack::Test::Methods

  let(:app) { PoziAPI::Application }

  it "should work" do
    get "/"
    last_response.should be_ok
  end

end

