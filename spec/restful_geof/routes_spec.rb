require "spec_helper"
require "restful_geof/routes"

require "stringio"

module RestfulGeof
  describe Routes do
    describe "#params" do

      subject { Routes }

      context "given invalid request" do
        let(:request) { stub(path_info: "/some/invalid/path").as_null_object }
        it "should return action unknown" do
          subject.new(request).params.should include(:action => :unknown)
        end
      end

      context "given valid request" do

        describe "create action" do

          let(:feature_json) { '{ "some": "GeoJSON" }' }
          let(:request) { mock(
            request_method: "POST",
            path_info: "/mydb/mytable",
            body: StringIO.new(feature_json)
          ) }

          it "should return the right params" do
            subject.new(request).params.should include(
              :action => :create,
              :database => "mydb", :table => "mytable",
              :body_json => feature_json
            )
          end

        end

        describe "delete action" do
          it "should work"
        end

        describe "update action" do
          it "should work"
        end
        
        describe "read action" do

          let(:request) { mock(request_method: "GET", path_info: "/mydb/mytable/22", body: StringIO.new) }

          it "should not be misinterpreted as a query" do
            params = subject.new(request).params
            params.should_not include(:action => :query)
            params.should include(:action => :read)
          end

          it "should return the correct params" do
            subject.new(request).params.should include(:action => :read, :id => "22")
          end

          it "should handle non-integer IDs" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/e99b71", body: StringIO.new)
            subject.new(request).params.should include(:id => "e99b71")
          end

        end

        describe "query actions" do
          
          it "should handle basic read requests" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable", body: StringIO.new)
            subject.new(request).params.should include(
              :action => :query,
              :database => "mydb", :table => "mytable"
            )
          end

          it "should handle field lookup conditions (as strings)" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/typeid/is/44", body: StringIO.new)
            params = subject.new(request).params
            params.should include(:action => :query, :database => "mydb", :table => "mytable")
            params[:conditions].should include(is: { "typeid" => "44" })
          end

          it "should handle 'in' conditions that have commas" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/name/in/foo,has%2Ccomma", body: StringIO.new)
            params = subject.new(request).params
            params.should include(:action => :query, :database => "mydb", :table => "mytable")
            params[:conditions].should include(in: { "name" => ["foo", "has,comma"] })
          end

          it "should get full text search conditions" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/groupid/is/2/name/matches/mr%20ed/limit/1", body: StringIO.new)
            params = subject.new(request).params
            params.should include(:action => :query, :database => "mydb", :table => "mytable")
            params[:conditions].should include(matches: { "name" => "mr ed" })
          end
          
          it "should get contains conditions" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/groupid/is/2/name/contains/mr%20ed%25/limit/3", body: StringIO.new)
            params = subject.new(request).params
            params.should include(:action => :query, :database => "mydb", :table => "mytable")
            params[:conditions].should include(contains: { "name" => "mr ed%" })
          end

          it "should get closest conditions"

          it "should get limit conditions" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/groupid/is/2/name/matches/mr%20ed/limit/3", body: StringIO.new)
            subject.new(request).params[:conditions].should include(limit: 3)
          end

          it "should not pass limit if not given" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/groupid/is/2/name/matches/mr%20ed", body: StringIO.new)
            subject.new(request).params[:conditions].keys.include?(:limit).should be_false
          end
          
          it "should say unknown if the URL doesn't match anything" do
            request = mock(request_method: "GET", path_info: "/somecrazyurlthatdoesnotmatchanything", body: StringIO.new)
            subject.new(request).params.should include(:action => :unknown)
          end

          it "should not match any action if the condition is something crazy" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/field/notarealcondition/value", body: StringIO.new)
            subject.new(request).params.should include(:action => :unknown)
          end

        end
        
      end


    end
  end
end

