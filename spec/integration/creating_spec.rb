require "spec_helper"
require "json_expressions/rspec"

require "restful_geof/app"

module RestfulGeof
  describe "Integration testing against PostGIS" do
    include Rack::Test::Methods
    let(:app) { App }

    before :all do
      GC.start
      %x{psql -f #{ROOT_PATH}/spec/resources/seeds.sql -U #{ENV["RESTFUL_GEOF_PG_USERNAME"] || ENV["USER"]}}
    end

    def around(number, precision=0.0000001)
      (number - precision)..(number + precision)
    end

    describe "creating" do
      let(:new_feature_json) {{
        "type" => "Feature", "properties" => { "name" => "new point" },
        "geometry" => {
          "type" => "Point", 
          "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
          "coordinates" => [143.584379916592, -38.3419002991608]
        }
      }.to_json}

      it "should should return the record with a new ID" do
        post "/restful_geof_test/spatial", new_feature_json
        first_id = JSON.parse(last_response.body)["properties"]["id"]
        post "/restful_geof_test/spatial", new_feature_json
        second_id = JSON.parse(last_response.body)["properties"]["id"]
        first_id.class.should == Fixnum
        second_id.class.should == Fixnum
        second_id.should >= first_id
      end

      it "should return the correct geometry" do
        post "/restful_geof_test/spatial", new_feature_json
        last_response.body.should match_json_expression({
          "type" => "Feature", "properties" => { "id" => Fixnum, "name" => "new point" },
          "geometry" => {
            "type" => "Point", 
            "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
            "coordinates" => [around(143.584379916592), around(-38.3419002991608)]
          }
        })
      end

      it "should save the record permanently, so it can be read back" do
        post "/restful_geof_test/spatial", new_feature_json
        new_id = JSON.parse(last_response.body)["properties"]["id"]
        get "/restful_geof_test/spatial/#{new_id}"
        last_response.body.should match_json_expression({
          "type" => "Feature", "properties" => { "id" => new_id, "name" => "new point" },
          "geometry" => {
            "type" => "Point", 
            "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
            "coordinates" => [around(143.584379916592), around(-38.3419002991608)]
          }
        })
      end

      it "should correctly insert into a table with SRID other than EPSG:4326" do
        pending # maybe this should be done by just adjusting the above examples to use the other_srid table
      end
      it "should reject GeoJSON not in EPSG:4326"
      it "should work with multiple features"

    end

  end
end

