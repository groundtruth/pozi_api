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

    describe "querying" do

      it "should have HTTP success code when called correctly" do
        get "/restful_geof_test/spatial"
        last_response.should be_ok
      end

      it "should return a GeoJSON feature collection of all data" do
        get "/restful_geof_test/spatial"
        last_response.body.should match_json_expression({
          "type" => "FeatureCollection",
          "features" => [
            {
              "type" => "Feature", "properties" => { "id" => 1, "name" => "first" },
              "geometry" => {
                "type" => "Point", 
                "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
                "coordinates" => [around(143.584379916592), around(-38.3419002991608)]
              }
            },
            {
              "type" => "Feature", "properties" => { "id" => 2, "name" => "second" },
              "geometry" => {
                "type" => "Point", 
                "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
                "coordinates" => [around(143.584379916592), around(-38.3419002991608)]
              }
            },
            {
              "type" => "Feature", "properties" => { "id" => 3, "name" => "third" },
              "geometry" => {
                "type" => "Point", 
                "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
                "coordinates" => [around(143.584379916592), around(-38.3419002991608)]
              }
            },
            {
              "type" => "Feature", "properties" => { "id" => 4, "name" => "123" },
              "geometry" => {
                "type" => "Point", 
                "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
                "coordinates" => [around(143.584379916592), around(-38.3419002991608)]
              }
            },
            {
              "type" => "Feature", "properties" => { "id" => 5, "name" => "no geometry" }
            }
          ]
        })
      end

      it "should return a HTTP error code if there is a database error" do
        get "/restful_geof_test/bad_table_name"
        last_response.should_not be_ok
      end

      it "should return an empty feature collection if there are no rows in the DB" do
        get "/restful_geof_test/empty"
        last_response.body.should match_json_expression({ "type" => "FeatureCollection", "features" => [] })
      end

      it "should handle non-spatial tables" do
        get "/restful_geof_test/non_spatial"
        last_response.body.should match_json_expression({
          "type" => "FeatureCollection",
          "features" => [
            { "type" => "Feature", "properties" => { "id" => 1, "name" => "first" } },
            { "type" => "Feature", "properties" => { "id" => 2, "name" => "second" } }
          ]
        })
      end

      it "should convert to EPSG 4326" do
        get "/restful_geof_test/other_srid"
        last_response.body.should match_json_expression({
          "type" => "FeatureCollection",
          "features" => [
              {
                  "type" => "Feature",
                  "properties" => { "id" => 1, "name" => "first" },
                  "geometry" => {
                    "type" => "Point", 
                    "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
                    "coordinates" => [around(143.584379393926), around(-38.3418996888383)]
                  }
              }
          ]
        })
      end

      describe "with conditions" do

        it "should handle limits" do
          get "/restful_geof_test/spatial/limit/2"
          last_response.body.should match_json_expression({
            "type" => "FeatureCollection",
            "features" => [wildcard_matcher, wildcard_matcher]
          })
        end

        describe "'is' conditions" do

          it "should handle integers" do
            get "/restful_geof_test/spatial/id/is/3"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [{ "properties" => { "id" => 3 }.ignore_extra_keys!  }.ignore_extra_keys!]
            })
          end

          it "should handle strings" do
            get "/restful_geof_test/spatial/name/is/second"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [{ "properties" => { "id" => 2 }.ignore_extra_keys!  }.ignore_extra_keys!]
            })
          end

          it "should handle strings of only digits" do
            get "/restful_geof_test/spatial/name/is/123"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [{ "properties" => { "id" => 4 }.ignore_extra_keys!  }.ignore_extra_keys!]
            })
          end

        end

        describe "'matches' conditions" do

          it "should find matching results" do
            get "/restful_geof_test/spatial/search_text/matches/come%20right"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [{ "properties" => { "id" => 2 }.ignore_extra_keys!  }.ignore_extra_keys!]
            })
          end

          it "should match when the last part is a prefix" do
            get "/restful_geof_test/spatial/search_text/matches/first%20seco"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [{ "properties" => { "id" => 2 }.ignore_extra_keys!  }.ignore_extra_keys!]
            })
          end

        end

        describe "'contains' conditions" do

          it "should be case insensitive" do
            get "/restful_geof_test/string_table/name/contains/22%20wills"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [
                { "type" => "Feature", "properties" => { "id" => 1, "name" => "1/22 Wills Street" } },
                { "type" => "Feature", "properties" => { "id" => 2, "name" => "22 Wills St" } }
              ].unordered!
            })
          end

          it "should return results ordered by proximity of matched string to left side" do
            get "/restful_geof_test/string_table/name/contains/22%20wills"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [
                { "type" => "Feature", "properties" => { "id" => 2, "name" => "22 Wills St" } },
                { "type" => "Feature", "properties" => { "id" => 1, "name" => "1/22 Wills Street" } }
              ].ordered!
            })
          end

        end

        it "should handle multple conditions, of different types" do
          get "/restful_geof_test/spatial/id/is/2/search_text/matches/seco"
          last_response.body.should match_json_expression({
            "type" => "FeatureCollection",
            "features" => [{ "properties" => { "id" => 2 }.ignore_extra_keys!  }.ignore_extra_keys!]
          })
        end

      end

    end

    describe "reading" do

      it "should read a specific record by ID" do
        get "/restful_geof_test/spatial/2"
        last_response.body.should match_json_expression({
          "type" => "FeatureCollection",
          "features" => [
            {
              "type" => "Feature", "properties" => { "id" => 2, "name" => "second" },
              "geometry" => {
                "type" => "Point", 
                "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
                "coordinates" => [around(143.584379916592), around(-38.3419002991608)]
              }
            },
          ]
        })
      end

      context "when ID does not exist" do

        before :each do
          get "/restful_geof_test/spatial/666"
        end

        it "should have 401 Not Found status code" do
          last_response.status.should == 404
        end

        it "should have empty collection as response body" do
          last_response.body.should match_json_expression({
            "type" => "FeatureCollection",
            "features" => []
          })
        end

      end

    end

  end
end

