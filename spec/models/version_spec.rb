require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require File.join(File.dirname(__FILE__), '..', 'page_spec_helper')

describe Version do

  include PageSpecHelper

  describe ".new" do
    attr_accessor :page

    before(:each) do
      self.page = stub_everything('page')
    end

    after(:each) do
      self.page = nil
    end
    
    it "should require content" do
      Version.new(valid_version_attributes.except(:content)).should have(1).error_on(:content)
    end
    
    it 'should have a content field' do
      Version.new(:content => 'How to make Merb cook breakfast...').content.should == 'How to make Merb cook breakfast...'
    end

    it 'should have a content_html field' do
      Version.new(:content_html => '<p>How to make Merb cook breakfast...</p>').content_html.should == '<p>How to make Merb cook breakfast...</p>'
    end
    
    it 'should have a created_at field' do
      creation_time = Time.now
      Version.new(:created_at => creation_time).created_at.should == creation_time
    end

    it 'should have a number field' do
      Version.new(:number => 10).number.should == 10
    end

    it 'should belong to a page' do
      Version.new(:page => page).page.should == page
    end
  end

  describe '#populate_html_content' do
    
    attr_accessor :version
    
    before(:each) do
      Version.publicize_methods do
        self.version = Version.new(:content => 'How to make [[Merb]] cook breakfast')
        version.populate_content_html
      end
    end
    
    after(:each) do
      self.version = nil
    end
    
    it 'should render content to HTML' do
      version.content_html.should match(/^<p>How to make/)
    end
    
    it 'should convert double-bracketed phrases to internal links' do
      version.content_html.should match(/<a href="\/pages\/merb">Merb<\/a>/)
    end
  end

  describe ".most_recent_unmoderated" do
    attr_accessor :versions
    
    before(:each) do
      self.versions = []
    end
    
    after(:each) do
      self.versions = nil
    end
    
    it "should find the most recent Versions" do
      Version.should_receive(:all).and_return(versions)
      Version.most_recent_unmoderated.should == versions
    end
  end

  describe '.recent' do
    before(:each) do
      @versions = []
      10.times { @versions.unshift(Version.gen) }
      Version.gen(:spam)
    end
    
    it 'should return the ten (by default) most recent non-spam versions' do
      Version.recent.should == @versions
    end
    
    it 'should accept an argument to return an arbitrary number of recent versions' do
      Version.recent(3).should == @versions[0..2]
    end
  end

  describe '.previous' do
    before(:each) do
      Version.delete_all
      Page.delete_all
      @page = Page.gen(:page_with_several_versions)
      @page.content = 17.random.words.join(' ')
      @page.save!
      @page.content = 17.random.words.join(' ')
      @page.save!
      @content = @page.versions.first.content
      @versions = @page.versions.items.sort { |a,b| a.number <=> b.number }
    end

    it 'should get the previous version for this page' do
      last_version = @versions.last
      last_version.number.should == 3
      last_version.previous.should == @versions[1]
    end
    
    it 'should get nil if no previous version' do
      last_version = @versions.first
      last_version.number.should == 1
      last_version.previous.should be_nil
    end
  end

  describe "#spam_or_ham" do
    it "should be 'spam' if the record is flagged as spam" do
      Version.new(:spam => true).spam_or_ham.should == "spam"
    end
    
    it "should be 'ham' if the record is not flagged as spam" do
      Version.new(:spam => false).spam_or_ham.should == "ham"
    end
  end

  describe ".create_spam" do
    after(:each) do
      Version.delete_all
    end
    
    it "should create a new record" do
      lambda { Version.create_spam("Name", valid_version_attributes) }.should change(Version, :count).by(1)
    end
    
    it "should create a new record that is marked as spam" do
      Version.create_spam("Name", valid_version_attributes).should be_spam
    end
    
    it "should have a page_id of -1" do
      Version.create_spam("Name", valid_version_attributes).page_id.should == -1
    end
    
    it "should pre-format the content" do
      Version.create_spam("Name", valid_version_attributes).content.should == [valid_version_attributes[:content], "Name"].join(":")
    end
  end

end
