require "spec_helper"
require "restful_geof/routes"

module RestfulGeof
  describe Routes do
    describe ".route" do

      context "given invalid request" do
        let(:request) { stub(path_info: "/some/invalid/path").as_null_object }
        it "should return 400 (Bad Request)" do
          subject.route(request).should == 400
        end
      end

      context "given valid request" do
        let(:model) { mock("Model") }

        before :each do
          Model.stub(:new).and_return(model)
        end
        
        describe "read actions" do
          
          it "should handle basic read requests, returning the result" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable")
            result = mock("result")
            Model.should_receive(:new).with("mydb", "mytable")
            model.should_receive(:find).and_return(result)
            subject.route(request).should == result
          end

          it "should handle field lookup conditions (as strings)" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/typeid/is/44")
            model.should_receive(:find).with(hash_including(is: { "typeid" => "44" }))
            subject.route(request)
          end

          it "should get full text search conditions" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/groupid/is/2/name/matches/mr%20ed/limit/1")
            model.should_receive(:find).with(hash_including(matches: { "name" => "mr ed" }))
            subject.route(request)
          end
          
          it "should get contains conditions" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/groupid/is/2/name/contains/mr%20ed%25/limit/3")
            model.should_receive(:find).with(hash_including(contains: { "name" => "mr ed%" }))
            subject.route(request)
          end

          it "should get limit conditions" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/groupid/is/2/name/matches/mr%20ed/limit/3")
            model.should_receive(:find).with(hash_including(limit: 3))
            subject.route(request)
          end

          it "should not pass limit if not given" do
            request = mock(request_method: "GET", path_info: "/mydb/mytable/groupid/is/2/name/matches/mr%20ed")
            model.should_receive(:find).with { |conditions| conditions.keys.include?(:limit).should be_false }
            subject.route(request)
          end

        end
        
      end


    end
  end
end

