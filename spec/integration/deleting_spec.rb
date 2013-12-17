require "spec_helper"

require "restful_geof/app"

module RestfulGeof
  describe "Integration testing against PostGIS" do
    include Rack::Test::Methods
    let(:app) { App }

    before(:all) { clean_db }

    describe "deleting" do
      let(:new_feature_json) {{
        "type" => "Feature", "properties" => { "name" => "new point" },
        "geometry" => {
          "type" => "Point", 
          "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
          "coordinates" => [143.584379916592, -38.3419002991608]
        }
      }.to_json}

      before :each do
        post "/restful_geof_test/spatial", new_feature_json
        last_response.should be_ok
        @new_id = JSON.parse(last_response.body)["properties"]["id"]
      end

      it "should delete a specific record by ID" do
        get "/restful_geof_test/spatial/#{@new_id}"
        last_response.should be_ok
        delete "/restful_geof_test/spatial/#{@new_id}"
        last_response.status.should == 204
        get "/restful_geof_test/spatial/#{@new_id}"
        last_response.status.should == 404
      end

      it "should handle non-spatial records" do
        json = { "type" => "Feature", "properties" => { "name" => "new point" } }.to_json
        post "/restful_geof_test/non_spatial", json
        last_response.should be_ok
        new_id = JSON.parse(last_response.body)["properties"]["id"]

        get "/restful_geof_test/non_spatial/#{new_id}"
        last_response.should be_ok
        delete "/restful_geof_test/non_spatial/#{new_id}"
        last_response.status.should == 204
        get "/restful_geof_test/non_spatial/#{new_id}"
        last_response.status.should == 404
      end

    end

  end
end

