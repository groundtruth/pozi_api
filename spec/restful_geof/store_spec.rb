require "spec_helper"
require "restful_geof/store"
require "json"

module RestfulGeof
  describe Store do

    let(:pg_host) { stub("pg_host") }
    let(:pg_port) { stub("pg_port") }
    let(:database) { stub("dbname") }
    let(:table) { stub("tablename") }
    let(:connection) { mock("connection", :db => database) }
    let(:column_info) {[
      { :column_name => "id", :udt_name => "integer" },
      { :column_name => "groupid", :udt_name => "int4" },
      { :column_name => "name", :udt_name => "varchar" },
      { :column_name => "the_geom", :udt_name => "geometry" }
    ]}

    subject { Store.new(database, table) }

    before :each do
      PG.stub(:connect).and_return(connection)
      connection.stub(:escape_string) { |str| str }
      connection.stub(:escape_identifier) { |str| str }
      connection.stub(:exec).with(/information_schema\.columns/).and_return(column_info)
      TableInfo.stub(:new).with(column_info).and_call_original
      Query.stub(:new).and_call_original
    end

    describe "#initialize" do

      before :each do
        ENV.stub(:[])
      end

      it "should connect to the Postgres instance specified by the env vars" do
        ENV.stub(:[]).with("RESTFUL_GEOF_PG_HOST").and_return(pg_host)
        ENV.stub(:[]).with("RESTFUL_GEOF_PG_PORT").and_return(pg_port)
        PG.should_receive(:connect).with(hash_including(host: pg_host, port: pg_port))
        subject
      end

      it "should connect without DB username/password if not given by environment variables" do
        PG.should_receive(:connect).with do |options|
          options.keys.include?(:user).should be_false
          options.keys.include?(:password).should be_false
        end
        subject
      end

      it "should connect using DB credentials from environment variables if given" do
        ENV.stub(:[]).with("RESTFUL_GEOF_PG_USERNAME").and_return("user")
        ENV.stub(:[]).with("RESTFUL_GEOF_PG_PASSWORD").and_return("pass")
        PG.should_receive(:connect).with(hash_including(user: "user", password: "pass"))
        subject
      end

      it "should connect to the right database" do
        PG.should_receive(:connect).with(hash_including(dbname: database))
        subject
      end

      it "should fail hard on DB connection errors (Sinatra should handle it)" do
        PG.should_receive(:connect).and_raise(PG::Error)
        lambda { subject }.should raise_error(PG::Error)
      end

    end

    describe "#find" do

      context "no results" do
        it "should render GeoJSON" do
          connection.should_receive(:exec).with(/the_geom/).and_return([])
          find_result = Store.new(database, table).find
          JSON.parse(find_result).should == { "type" => "FeatureCollection", "features" => [] }
        end
      end

      context "with results" do

        it "should render GeoJSON (for results with or without geometries)" do
          connection.should_receive(:exec).with(/the_geom/).and_return([
            { :id => 11, :name => "somewhere", :geometry_geojson => nil },
            { :id => 22, :name => "big one", :geometry_geojson => '{"type":"Point","coordinates":[145.716104000000001,-38.097603999999997]}' }
          ])
          JSON.parse(subject.find).should == {
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

        describe "with conditions" do

          it "should include limit clauses" do
            connection.should_receive(:exec).with(/LIMIT 22/)
            subject.find({ :limit => 22 })
          end

          it "should include 'is' conditions with integer values" do
            # connection.should_receive(:exec).with{ |sql| sql.should match(/groupid = 22/) }
            connection.should_receive(:exec).with(/groupid = 22/)
            subject.find({ :is => { "groupid" => "22" }})
          end

          it "should include 'is' conditions with string values" do
            connection.should_receive(:exec).with(/name = 'world'/)
            subject.find({ :is => { "name" => "world" }})
          end

          it "should include 'contains' conditions (with correct escaping)" do
            connection.should_receive(:exec).with(/name::varchar ILIKE '%world\\%%'/)
            subject.find({ :contains => { "name" => "world%" }})
          end

          it "should order results with 'contains' conditions" do
            connection.should_receive(:exec).with(/ORDER BY position/)
            subject.find({ :contains => { "name" => "world" }})
          end

          it "should include 'matches' conditions" do
            connection.should_receive(:exec).with(/ts_address @@/)
            subject.find({ :matches => { "ts_address" => "Main Stree" }})
          end

        end

      end

    end

  end
end

