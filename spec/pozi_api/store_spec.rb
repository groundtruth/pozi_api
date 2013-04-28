require "spec_helper"
require "pozi_api/store"
require "json"

module PoziAPI
  describe Store do

    let(:connection) { mock("connection") }
    let(:pg_host) { stub("pg_host") }
    let(:pg_port) { stub("pg_port") }
    let(:database) { stub("dbname") }
    let(:table) { stub("tablename") }

    subject { Store.new(database, table) }

    before :each do
      PG.stub(:connect).and_return(connection)
      connection.stub(:escape_string)
    end

    describe "#initialize" do

      before :each do
        connection.stub(:exec)
      end

      it "should connect to the Postgres instance specified by the env vars" do
        ENV.stub(:[]).with("POZI_API_PG_HOST").and_return(pg_host)
        ENV.stub(:[]).with("POZI_API_PG_PORT").and_return(pg_port)
        PG.should_receive(:connect).with(hash_including(host: pg_host, port: pg_port))
        subject.class.new(database, table)
      end

      it "should connect to the right database" do
        PG.should_receive(:connect).with(hash_including(dbname: database))
        subject.class.new(database, table)
      end

      it "should fail hard on DB connection errors (Sinatra should handle it)" do
        PG.should_receive(:connect).and_raise(PG::Error)
        lambda { subject.class.new(database, table) }.should raise_error(PG::Error)
      end

    end

    describe "column info methods" do

      before :each do
        connection.stub(:exec).and_return([
          { "column_name" => "id", "udt_name" => "integer" },
          { "column_name" => "name", "udt_name" => "varchar" },
          { "column_name" => "the_geom", "udt_name" => "geometry" }
        ])
      end

      describe "#geometry_column" do
        it "should identify the (first) geometry column" do
          subject.geometry_column.should == "the_geom"
        end
      end

      describe "#non_geometry_columns" do
        it "should identify the non-geometry columns" do
          subject.non_geometry_columns.should == ["id", "name"]
        end
      end
      
    end

    describe "#read" do

      context "no results" do
        it "should render GeoJSON" do
          connection.should_receive(:exec).any_number_of_times.and_return([])
          read_result = Store.new(database, table).read
          JSON.parse(read_result).should == { "type" => "FeatureCollection", "features" => [] }
        end
      end

      context "with results" do
        it "should render GeoJSON (for results with or without geometries)" do
          connection.should_receive(:exec).and_return(
            [
              { "column_name" => "id", "udt_name" => "integer" },
              { "column_name" => "name", "udt_name" => "varchar" },
              { "column_name" => "the_geom", "udt_name" => "geometry" }
            ],
            [
              { "id" => 11, "name" => "somewhere", "geometry_geojson" => nil },
              { "id" => 22, "name" => "big one", "geometry_geojson" => '{"type":"Point","coordinates":[145.716104000000001,-38.097603999999997]}' }
            ]
          )
          JSON.parse(subject.read).should == {
            "type" => "FeatureCollection",
            "features" => [
              {
                "type" => "Feature",
                "properties" => { "id" => 11, "name" => "somewhere" }
              },
              {
                "type" => "Feature",
                "properties" => { "id" => 22, "name" => "big one" },
                "geometry" => { "type" => "Point", "coordinates" => [145.716104, -38.097604] }
              }
            ]
          }
        end
      end

    end

  end
end

