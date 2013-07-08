require "spec_helper"
require "restful_geof/table_info"

module RestfulGeof
  describe TableInfo do

    let(:column_info) {[
      { :column_name => "id", :udt_name => "integer" },
      { :column_name => "name", :udt_name => "varchar" },
      { :column_name => "bignum", :udt_name => "int8" },
      { :column_name => "the_geom", :udt_name => "geometry" },
      { :column_name => "search_text_one", :udt_name => "tsvector" },
      { :column_name => "search_text_two", :udt_name => "tsvector" },
      { :column_name => "ogc_fid", :udt_name => "integer" },
      { :column_name => "ogr_fid", :udt_name => "integer" },
      { :column_name => "fid", :udt_name => "integer" },
      { :column_name => "anothernum", :udt_name => "integer" }
    ]}

    subject { TableInfo.new(column_info[0..5]) }

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
        subject.normal_columns.should == ["id", "name", "bignum"]
      end
    end

    describe "#integer_col?" do
      it "should return true if the column is any integer type" do
        subject.integer_col?("id").should be_true
        subject.integer_col?("bignum").should be_true
      end
      it "should return false if the column is not an integer type" do
        subject.integer_col?("name").should be_false
      end
    end

    describe "#id_column" do
      def info_without(cols)
        TableInfo.new(column_info.reject { |c| cols.include?(c[:column_name]) })
      end
      it "should choose a column named id, first" do
        info_without([]).id_column.should == "id"
      end
      it "should choose a column named ogc_fid, if no id" do
        info_without(%w{id}).id_column.should == "ogc_fid"
      end
      it "should choose a column named ogr_fid, if no id or ogc_fid" do
        info_without(%w{id ogc_fid}).id_column.should == "ogr_fid"
      end
      it "should choose a column named fid, if no id, ogc_fid or ogr_fid" do
        info_without(%w{id ogc_fid ogr_fid}).id_column.should == "fid"
      end
      it "should choose the first integer column if no id, ogc_fid, ogr_fid or fid" do
        info_without(%w{id ogc_fid ogr_fid fid}).id_column.should == "bignum"
      end
      it "should raise an error if no id column could be detected" do
        expect{ info_without(%w{id ogc_fid ogr_fid fid bignum anothernum}).id_column }.to raise_error()
      end
    end

  end
end

