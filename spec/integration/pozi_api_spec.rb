require "spec_helper"
require "json"

require "pozi_api/app"

module PoziAPI
  describe "Pozi API integration" do
    include Rack::Test::Methods
    let(:app) { App }

    before :all do
      %x{psql -f #{ROOT_PATH}/spec/resources/seeds.sql}
    end

    describe "reading" do
      it "should read all the data" do
        expected = JSON.parse(File.read("#{ROOT_PATH}/spec/resources/read.json"))
        get "/api/pozi_api_test/test_data"
        last_response.should be_ok
        result = JSON.parse(last_response.body)
        result.should == expected
      end
    end

  end
end

