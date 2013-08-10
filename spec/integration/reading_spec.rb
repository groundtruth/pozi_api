require "spec_helper"
require "json_expressions/rspec"

require "restful_geof/app"

module RestfulGeof
  describe "Integration testing against PostGIS" do
    include Rack::Test::Methods
    let(:app) { App }

    before :all do
      %x{psql -f #{ROOT_PATH}/spec/resources/seeds.sql -U #{ENV["RESTFUL_GEOF_PG_USERNAME"] || ENV["USER"]}}
    end

    def around(number, precision=0.0000001)
      (number - precision)..(number + precision)
    end

    describe "reading" do

      it "should read a specific record by ID" do
        get "/restful_geof_test/spatial/2"
        last_response.body.should match_json_expression({
          "type" => "Feature", "properties" => { "id" => 2, "name" => "second" },
          "geometry" => {
            "type" => "Point", 
            "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
            "coordinates" => [around(141.584379916592), around(-36.3419002991608)]
          }
        })
      end

      context "when ID does not exist" do

        before :each do
          get "/restful_geof_test/spatial/666"
        end

        it "should have 404 Not Found status code" do
          last_response.status.should == 404
        end

        it "should have empty collection as response body" do
          last_response.body.should == "{}"
        end

      end

    end

  end
end

