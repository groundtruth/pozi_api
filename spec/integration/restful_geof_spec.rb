require "spec_helper"
require "json"

require "restful_geof/app"

module RestfulGeof
  describe "Pozi API integration" do
    include Rack::Test::Methods
    let(:app) { App }

    before :all do
      %x{psql -f #{ROOT_PATH}/spec/resources/seeds.sql -U #{ENV["RESTFUL_GEOF_PG_USERNAME"] || ENV["USER"]}}
    end

    describe "reading" do

      it "should have HTTP success code when called correctly" do
        get "/api/restful_geof_test/spatial"
        last_response.should be_ok
      end

      it "should return a GeoJSON feature collection of all data" do
        get "/api/restful_geof_test/spatial"
        JSON.parse(last_response.body).should == JSON.parse(File.read("#{ROOT_PATH}/spec/resources/spatial.json"))
      end

      it "should return a HTTP error code if there is a database error" do
        get "/api/restful_geof_test/bad_table_name"
        last_response.should_not be_ok
      end

      it "should return an empty feature collection if there are no rows in the DB" do
        get "/api/restful_geof_test/empty"
        JSON.parse(last_response.body).should == JSON.parse(File.read("#{ROOT_PATH}/spec/resources/empty.json"))
      end

      it "should handle non-spatial tables" do
        get "/api/restful_geof_test/non_spatial"
        JSON.parse(last_response.body).should == JSON.parse(File.read("#{ROOT_PATH}/spec/resources/non_spatial.json"))
      end

      it "should convert to EPSG 4326" do
        get "/api/restful_geof_test/other_srid"
        JSON.parse(last_response.body).should == JSON.parse(File.read("#{ROOT_PATH}/spec/resources/other_srid.json"))
      end

      describe "with conditions" do

        it "should handle limits" do
          get "/api/restful_geof_test/spatial/limit/2"
          JSON.parse(last_response.body)["features"].count.should == 2
        end

        it "should handle an 'is' condition with an integer" do
          get "/api/restful_geof_test/spatial/id/is/3"
          result = JSON.parse(last_response.body)
          result["features"].count.should == 1
          result["features"].first["properties"]["id"].should == 3
        end

        it "should handle an 'is' condition with a string" do
          get "/api/restful_geof_test/spatial/name/is/second"
          result = JSON.parse(last_response.body)
          result["features"].count.should == 1
          result["features"].first["properties"]["id"].should == 2
        end

        it "should handle 'matches' conditions" do
          get "/api/restful_geof_test/spatial/search_text/matches/come%20right"
          result = JSON.parse(last_response.body)
          result["features"].count.should == 1
          result["features"].first["properties"]["id"].should == 2
        end

      end

    end

  end
end

