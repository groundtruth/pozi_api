require "spec_helper"
require "pozi_api/routes"

module PoziAPI
  describe Routes do
    describe ".route" do

      context "given invalid request" do
        let(:request) { stub(path_info: "/some/invalid/path").as_null_object }
        it "should return 400 (Bad Request)" do
          subject.route(request).should == 400
        end
      end

      context "given valid request" do
        let(:store) { mock("Store") }

        before :each do
          Store.stub(:new).and_return(store)
        end
        
        it "should handle read requests" do
          request = mock(request_method: "GET", path_info: "#{Routes::PREFIX}/mydb/mytable")
          result = mock("result")
          Store.should_receive(:new).with("mydb", "mytable")
          store.should_receive(:read).and_return(result)
          subject.route(request).should == result
        end

      end


    end
  end
end

