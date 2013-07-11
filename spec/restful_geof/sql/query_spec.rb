require "spec_helper"
require "restful_geof/sql/query"

module RestfulGeof
  module SQL

    describe Query do

      it "should SELECT all if fields unspecified" do
        subject.from("table").to_sql.should match(/SELECT \*/)
      end
      it "should SELECT cols requested" do
        subject.select("id", "name")
        subject.select("third")
        subject.from("mytable")
        subject.to_sql.should match(/SELECT id, name, third/)
      end

      it "should include FROM correctly" do
        subject.from("mytable").to_sql.should match(/FROM mytable/)
      end
      it "should raise an error if no FROM clause defined" do
        expect { subject.to_sql }.to raise_error
      end
      it "should raise an error if multiple FROMs" do
        subject.from("mytable")
        expect { subject.from("jointable") }.to raise_error
      end

      it "should terminate with semicolon" do
        subject.from("mytable").to_sql.should match(/;/)
      end

      it "should join WHERE conditions with AND" do
        subject.from("mytable").where("id = 22").where("size > 10")
        subject.to_sql.should match(/WHERE id = 22 AND size > 10/)
      end
      it "should not include WHERE unless asked" do
        subject.from("mytable").to_sql.should_not match(/WHERE/i)
      end

      it "should join ORDER BY things with comma" do
        subject.from("mytable").order_by("size DESC").order_by("importance")
        subject.to_sql.should match(/ORDER BY size DESC, importance/)
      end
      it "should not include ORDER BY unless asked" do
        subject.from("mytable").to_sql.should_not match(/ORDER BY/i)
      end

      it "should include LIMIT if asked" do
        subject.from("mytable").limit(22).to_sql.should match(/LIMIT 22/)
      end
      it "should not include LIMIT unless asked" do
        subject.from("mytable").to_sql.should_not match(/LIMIT/i)
      end

    end

  end
end

