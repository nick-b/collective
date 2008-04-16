require File.join(File.dirname(__FILE__), "..", 'spec_helper.rb')

describe Edits do
  attr_accessor :edit, :edits
  
  before(:each) do
    self.edit  = Version.new(
      :content   => "I have content", 
      :signature => 1234, 
      :spam      => false
    )
    self.edits = [edit]
  end
  
  after(:each) do
    self.edit  = nil
    self.edits = nil
  end
  
  describe "requesting /edits with GET" do
    before(:each) do
      Version.stub!(:most_recent_unmoderated).and_return(edits)
    end
    
    def do_get
      dispatch_to(Edits, :index) do |controller|
        controller.stub!(:authenticate_or_request_with_http_basic).and_return(true)
        controller.stub!(:display)
        yield(controller) if block_given?
      end
    end
    
    it "should be successful" do
      do_get.should be_successful
    end
    
    it "should render the records" do
      do_get do |controller|
        controller.should_receive(:display).with(edits)
      end
    end
    
    it "should load the most recent Versions available" do
      Version.should_receive(:most_recent_unmoderated).and_return(edits)
      do_get.assigns(:edits).should == edits
    end
    
    it "should return an HTTP 401 (UNAUTHORIZED) response if the user isn't authenticated" do
      dispatch_to(Edits, :index).status.should == 401
    end
  end
  
  describe "requesting /edits/1 with PUT" do
    
    before(:each) do
      Version.stub!(:first).and_return(edit)
      Viking.stub!(:mark_as_spam_or_ham)
      edit.stub!(:update_attributes).and_return(true)
    end
    
    def do_put
      dispatch_to(Edits, :update, :id => "1", :page => {}) do |controller|
        controller.stub!(:authenticate_or_request_with_http_basic).and_return(true)
      end
    end
    
    def do_xhr_put
      dispatch_to(Edits, :update, :id => "1", :page => {}, :format => 'js') do |controller|
        controller.stub!(:authenticate_or_request_with_http_basic).and_return(true)
      end
    end
    
    it "should load the requested Version" do
      Version.should_receive(:first).with("1").and_return(edit)
      do_put.assigns(:edit).should == edit
    end
    
    it "should raise NotFound if an invalid ID is provided" do
      Version.should_receive(:first).with("1").and_return(nil)
      lambda { do_put }.should raise_error(Merb::ControllerExceptions::NotFound)
    end
    
    it "should update the record's attributes" do
      edit.should_receive(:update_attributes).and_return(true)
      do_put
    end
    
    it "should update the record's spam or ham status" do
      Viking.should_receive(:mark_as_spam_or_ham).with(edit.spam?, :signatures => edit.signature)
      do_put
    end
    
    it "should redirect_to /edits if the update was successful" do
      do_put.should be_redirection_to(url(:edits))
    end
    
    it "should render nothing if the request is XHR" do
      do_xhr_put.should be_successful
    end
    
    it "should raise BadRequest if the update fails" do
      edit.should_receive(:update_attributes).and_return(false)
      lambda { do_put }.should raise_error(Merb::ControllerExceptions::BadRequest)
    end
        
  end
  
end
