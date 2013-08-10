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
                "coordinates" => [around(140.584379916592), around(-35.3419002991608)]
              }
            },
            {
              "type" => "Feature", "properties" => { "id" => 2, "name" => "second" },
              "geometry" => {
                "type" => "Point", 
                "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
                "coordinates" => [around(141.584379916592), around(-36.3419002991608)]
              }
            },
            {
              "type" => "Feature", "properties" => { "id" => 3, "name" => "third" },
              "geometry" => {
                "type" => "Point", 
                "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
                "coordinates" => [around(142.584379916592), around(-37.3419002991608)]
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
        pending "better error handling"
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

      it "should wrap the results in a JSONP callback if asked via a 'jsonp' parameter" do
        get "/restful_geof_test/spatial"
        unwrapped_data = last_response.body
        get "/restful_geof_test/spatial?jsonp=myHandler"
        last_response.body.should == "myHandler(#{unwrapped_data});"
      end

      it "should wrap the results in a JSONP callback if asked via a 'callback' parameter" do
        get "/restful_geof_test/spatial"
        unwrapped_data = last_response.body
        get "/restful_geof_test/spatial?callback=myHandler"
        last_response.body.should == "myHandler(#{unwrapped_data});"
      end

      it "should be able to read tricky characters from the database" do
        pending
        # for example, this character: – 
        # which isn't like the normal: -
      end

      describe "with conditions" do

        it "should handle limits" do
          get "/restful_geof_test/spatial/limit/2"
          last_response.body.should match_json_expression({
            "type" => "FeatureCollection",
            "features" => [wildcard_matcher, wildcard_matcher]
          })
        end

        describe "'closest' conditions" do

          it "should get the closest" do
            get "/restful_geof_test/spatial/closest/141.584379916592/-36.3419002991608/limit/1"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [{
                "type" => "Feature", "properties" => { "id" => 2, "name" => "second" },
                "geometry" => {
                  "type" => "Point", 
                  "crs"=> { "type"=>"name", "properties"=> { "name" => "EPSG:4326" } },
                  "coordinates" => [around(141.584379916592), around(-36.3419002991608)]
                }
              }]
            })
          end

          it "should order results by distance from the specified point" do
            get "/restful_geof_test/spatial/closest/143.584379916592/-38.3419002991608/limit/2"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [
                {
                  "type" => "Feature", "properties" => { "id" => 4, "name" => "123" },
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
                    "coordinates" => [around(142.584379916592), around(-37.3419002991608)]
                  }
                }
              ]
            })
          end

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

        describe "'in' conditions" do

          it "should handle integers" do
            get "/restful_geof_test/spatial/id/in/2,3,4"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [
                { "properties" => { "id" => 2 }.ignore_extra_keys!  }.ignore_extra_keys!,
                { "properties" => { "id" => 3 }.ignore_extra_keys!  }.ignore_extra_keys!,
                { "properties" => { "id" => 4 }.ignore_extra_keys!  }.ignore_extra_keys!
              ]
            })
          end

          it "should handle strings" do
            get "/restful_geof_test/spatial/name/in/first,third"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [
                { "properties" => { "id" => 1 }.ignore_extra_keys!  }.ignore_extra_keys!,
                { "properties" => { "id" => 3 }.ignore_extra_keys!  }.ignore_extra_keys!
              ]
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
                { "type" => "Feature", "properties" => { "id" => 3, "name" => "22 Wills Other St" } },
                { "type" => "Feature", "properties" => { "id" => 1, "name" => "1/22 Wills Street" } },
                { "type" => "Feature", "properties" => { "id" => 2, "name" => "22 Wills St" } }
              ].unordered!
            })
          end

          it "should return results ordered by proximity of matched string to left side, then alphabetical order" do
            get "/restful_geof_test/string_table/name/contains/22%20wills"
            last_response.body.should match_json_expression({
              "type" => "FeatureCollection",
              "features" => [
                { "type" => "Feature", "properties" => { "id" => 3, "name" => "22 Wills Other St" } },
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

  end
end

