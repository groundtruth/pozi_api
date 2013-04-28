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

      it "should have HTTP success code when called correctly" do
        get "/api/pozi_api_test/spatial"
        last_response.should be_ok
      end

      it "should return a GeoJSON feature collection of all data" do
        get "/api/pozi_api_test/spatial"
        JSON.parse(last_response.body).should == JSON.parse(File.read("#{ROOT_PATH}/spec/resources/spatial.json"))
      end

      it "should return a HTTP error code if there is a database error" do
        get "/api/pozi_api_test/bad_table_name"
        last_response.should_not be_ok
      end

      it "should return an empty feature collection if there are now rows in the DB" do
        get "/api/pozi_api_test/empty"
        JSON.parse(last_response.body).should == JSON.parse(File.read("#{ROOT_PATH}/spec/resources/empty.json"))
      end

      it "should handle non-spatial tables" do
        get "/api/pozi_api_test/non_spatial"
        JSON.parse(last_response.body).should == JSON.parse(File.read("#{ROOT_PATH}/spec/resources/non_spatial.json"))
      end

      it "should convert to EPSG 4326" do
        get "/api/pozi_api_test/other_srid"
        JSON.parse(last_response.body).should == JSON.parse(File.read("#{ROOT_PATH}/spec/resources/other_srid.json"))
      end
    end

  end
end

