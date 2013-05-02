require "spec_helper"
require "json_expressions/rspec"

require "restful_geof/app"

module RestfulGeof
  describe "Pozi API integration" do
    include Rack::Test::Methods
    let(:app) { App }

    before :all do
      %x{psql -f #{ROOT_PATH}/spec/resources/seeds.sql -U #{ENV["RESTFUL_GEOF_PG_USERNAME"] || ENV["USER"]}}
    end

    def around(number, precision=0.0000001)
      (number - precision)..(number + precision)
    end

    describe "reading" do

      it "should have HTTP success code when called correctly" do
        get "/api/restful_geof_test/spatial"
        last_response.should be_ok
      end

      it "should return a GeoJSON feature collection of all data" do
        get "/api/restful_geof_test/spatial"
        last_response.body.should match_json_expression({
          "type" => "FeatureCollection",
          "features" => [
            {
              "type" => "Feature", "properties" => { "id" => 1, "name" => "first" },
              "geometry" => { "type" => "Point", "coordinates" => [around(143.584379916592), around(-38.3419002991608)] }
            },
            {
              "type" => "Feature", "properties" => { "id" => 2, "name" => "second" },
              "geometry" => { "type" => "Point", "coordinates" => [around(143.584379916592), around(-38.3419002991608)] }
            },
            {
              "type" => "Feature", "properties" => { "id" => 3, "name" => "third" },
              "geometry" => { "type" => "Point", "coordinates" => [around(143.584379916592), around(-38.3419002991608)] }
            },
            {
              "type" => "Feature", "properties" => { "id" => 4, "name" => "no geometry" }
            }
          ]
        })
      end

      it "should return a HTTP error code if there is a database error" do
        get "/api/restful_geof_test/bad_table_name"
        last_response.should_not be_ok
      end

      it "should return an empty feature collection if there are no rows in the DB" do
        get "/api/restful_geof_test/empty"
        last_response.body.should match_json_expression({ "type" => "FeatureCollection", "features" => [] })
      end

      it "should handle non-spatial tables" do
        get "/api/restful_geof_test/non_spatial"
        last_response.body.should match_json_expression({
          "type" => "FeatureCollection",
          "features" => [
            { "type" => "Feature", "properties" => { "id" => 1, "name" => "first" } },
            { "type" => "Feature", "properties" => { "id" => 2, "name" => "second" } }
          ]
        })
      end

      it "should convert to EPSG 4326" do
        get "/api/restful_geof_test/other_srid"
        last_response.body.should match_json_expression({
          "type" => "FeatureCollection",
          "features" => [
              {
                  "type" => "Feature", "properties" => { "id" => 1, "name" => "first" },
                  "geometry" => { "type" => "Point", "coordinates" => [around(143.584379393926), around(-38.3418996888383)] }
              }
          ]
        })
      end

      describe "with conditions" do

        it "should handle limits" do
          get "/api/restful_geof_test/spatial/limit/2"
          last_response.body.should match_json_expression({
            "type" => "FeatureCollection",
            "features" => [wildcard_matcher, wildcard_matcher]
          })
        end

        it "should handle an 'is' condition with an integer" do
          get "/api/restful_geof_test/spatial/id/is/3"
          last_response.body.should match_json_expression({
            "type" => "FeatureCollection",
            "features" => [{ "properties" => { "id" => 3 }.ignore_extra_keys!  }.ignore_extra_keys!]
          })
        end

        it "should handle an 'is' condition with a string" do
          get "/api/restful_geof_test/spatial/name/is/second"
          last_response.body.should match_json_expression({
            "type" => "FeatureCollection",
            "features" => [{ "properties" => { "id" => 2 }.ignore_extra_keys!  }.ignore_extra_keys!]
          })
        end

        it "should handle 'matches' conditions" do
          get "/api/restful_geof_test/spatial/search_text/matches/come%20right"
          last_response.body.should match_json_expression({
            "type" => "FeatureCollection",
            "features" => [{ "properties" => { "id" => 2 }.ignore_extra_keys!  }.ignore_extra_keys!]
          })
        end

      end

    end

  end
end

