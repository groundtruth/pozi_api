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

    before :each do
      PG.stub(:connect).and_return(connection)
    end

    describe "#initialize" do

      it "should connect to the Postgres instance specified by the env vars" do
        ENV.stub(:[]).with("POZI_API_PG_HOST").and_return(pg_host)
        ENV.stub(:[]).with("POZI_API_PG_PORT").and_return(pg_port)
        PG.should_receive(:connect).with(hash_including(host: pg_host, port: pg_port))
        Store.new(database, table)
      end

      it "should connect to the right database" do
        PG.should_receive(:connect).with(hash_including(dbname: database))
        Store.new(database, table)
      end

      it "should handle connection errors" do
        pending
      end

    end

    describe "#read" do

      context "no results" do
        it "should render GeoJSON" do
          connection.should_receive(:exec).with(/SELECT .+ FROM #{Regexp.escape table}/).and_return([])
          read_result = Store.new(database, table).read
          JSON.parse(read_result).should == { "type" => "FeatureCollection", "features" => [] }
        end
      end

      context "with results" do
        it "should render GeoJSON" do
          pending
        end
      end

    end

  end
end

