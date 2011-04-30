require 'spec_helper'

describe RegisteredAttendeesController do
  render_views
  
  it_should_require_login_for_actions :index, :show, :update

  before(:each) do
    @conference = Factory(:conference)
    @user ||= Factory(:user)
    sign_in @user
    disable_authorization
  end
  
  describe "GET index" do
    it "should render index template" do
      get :index
      response.should render_template(:index)
    end
  end
  
  describe "GET show" do
    before do
      @attendee ||= Factory(:attendee)
    end
    
    it "should render show template" do
      get :show, :id => @attendee.id
      response.should render_template(:show)
    end
  end
  
  describe "PUT update" do
    before do
      @attendee ||= Factory(:attendee)
      @email = stub(:deliver => true)
      EmailNotifications.stubs(:registration_confirmed).returns(@email)
    end
    
    it "update action should render show template when model is invalid" do
      pending
      # +stubs(:valid?).returns(false)+ doesn't work here because
      # inherited_resources does +obj.errors.empty?+ to determine
      # if validation failed
      put :update, :id => @attendee.id, :attendee => {}
      response.should render_template(:show)
    end

    it "update action should redirect when model is valid" do
      @attendee.stubs(:valid?).returns(true)
      put :update, :id => @attendee.id
      response.should redirect_to(registered_attendees_path)
    end
    
    it "should send confirmed registration e-mail" do
      EmailNotifications.expects(:registration_confirmed).returns(@email)
      @attendee.stubs(:valid?).returns(true)
      post :update, :id => @attendee.id
    end
  end
end