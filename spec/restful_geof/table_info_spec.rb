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

    def subject_without(other_cols=[])
      TableInfo.new(column_info.reject { |col| other_cols.include?(col[:column_name]) })
    end

    let(:normal_subject) {
      subject_without(%w{ogc_fid ogr_fid fid anothernum})
    }

    describe "#initialize" do
      it "should raise an error if no id column could be detected" do
        expect{ subject_without(%w{id ogc_fid ogr_fid fid bignum anothernum}) }.to raise_error()
      end
    end

    describe "#tsvector_columns" do
      it "should identify any columns" do
        normal_subject.tsvector_columns.should == ["search_text_one", "search_text_two"]
      end
    end

    describe "#geometry_column" do
      it "should identify the (first) geometry column" do
        normal_subject.geometry_column.should == "the_geom"
      end
    end

    describe "#normal_columns" do
      it "should identify normal columns for shoing in properties part of GeoJSON" do
        normal_subject.normal_columns.should == ["id", "name", "bignum"]
      end
    end

    describe "#integer_col?" do
      it "should return true if the column is any integer type" do
        normal_subject.integer_col?("id").should be_true
        normal_subject.integer_col?("bignum").should be_true
      end
      it "should return false if the column is not an integer type" do
        normal_subject.integer_col?("name").should be_false
      end
    end

    describe "#id_column" do
      it "should choose a column named id, first" do
        subject_without([]).id_column.should == "id"
      end
      it "should choose a column named ogc_fid, if no id" do
        subject_without(%w{id}).id_column.should == "ogc_fid"
      end
      it "should choose a column named ogr_fid, if no id or ogc_fid" do
        subject_without(%w{id ogc_fid}).id_column.should == "ogr_fid"
      end
      it "should choose a column named fid, if no id, ogc_fid or ogr_fid" do
        subject_without(%w{id ogc_fid ogr_fid}).id_column.should == "fid"
      end
      it "should choose the first integer column if no id, ogc_fid, ogr_fid or fid" do
        subject_without(%w{id ogc_fid ogr_fid fid}).id_column.should == "bignum"
      end
    end

  end
end

