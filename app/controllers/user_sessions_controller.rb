class UserSessionsController < InheritedResources::Base
  before_filter :login_required, :only => :destroy
  before_filter :logout_required, :only => :create

  actions :new, :create
  
  def new
    flash.now[:news] = t('flash.news.vote')
    new!
  end
  
  def create
    create! do |success, failure|
      success.html do
        flash[:notice] = t('flash.user_session.create.success')
        redirect_to_target_or_default(root_url)
      end
      failure.html do        
        flash.now[:error] = @user_session.errors.on(:base) unless @user_session.errors.on(:base).blank?
        render :new
      end
    end
  end
  
  def destroy
    @user_session = UserSession.find
    @user_session.destroy
    flash[:notice] = t('flash.user_session.destroy.success')
    redirect_to root_url
  end
end
