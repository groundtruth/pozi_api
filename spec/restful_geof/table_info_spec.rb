require "spec_helper"
require "restful_geof/table_info"

module RestfulGeof
  describe TableInfo do

    subject {
      TableInfo.new([
        { :column_name => "id", :udt_name => "integer" },
        { :column_name => "name", :udt_name => "varchar" },
        { :column_name => "the_geom", :udt_name => "geometry" },
        { :column_name => "search_text_one", :udt_name => "tsvector" },
        { :column_name => "search_text_two", :udt_name => "tsvector" }
      ])
    }

    describe "#tsvector_columns" do
      it "should identify any columns" do
        subject.tsvector_columns.should == ["search_text_one", "search_text_two"]
      end
    end

    describe "#geometry_column" do
      it "should identify the (first) geometry column" do
        subject.geometry_column.should == "the_geom"
      end
    end

    describe "#normal_columns" do
      it "should identify normal columns for shoing in properties part of GeoJSON" do
        subject.normal_columns.should == ["id", "name"]
      end
    end

    describe "#integer_col?" do
      it "should work" do
        pending
      end
    end

  end
end

