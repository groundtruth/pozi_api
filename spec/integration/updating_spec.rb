require "spec_helper"

require "restful_geof/app"

module RestfulGeof
  describe "Integration testing against PostGIS" do
    include Rack::Test::Methods
    let(:app) { App }

    describe "updating" do

      before :each do
        @feature = {
          "type" => "Feature", "properties" => { "name" => "new point" },
          "geometry" => {
            "type" => "Point", 
            "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
            "coordinates" => [143.584379916592, -38.3419002991608]
          }
        }
        post "/restful_geof_test/spatial", @feature.to_json
        last_response.should be_ok
        @id = JSON.parse(last_response.body)["properties"]["id"]
        @feature["properties"]["id"] = @id
      end

      it "should update a specific record by ID" do
        @feature["properties"]["name"] = "old point, new name"
        put "/restful_geof_test/spatial/#{@id}", @feature.to_json
        last_response.should be_ok
        JSON.parse(last_response.body)["properties"]["name"].should == "old point, new name"

        get "/restful_geof_test/spatial/#{@id}"
        last_response.should be_ok
        JSON.parse(last_response.body)["properties"]["name"].should == "old point, new name"
      end

    end

  end
end

