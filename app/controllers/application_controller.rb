# encoding: UTF-8
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :sessions_by_track
  helper_method :sessions_by_type
  helper_method :gravatar_url
  protect_from_forgery

  around_filter :set_locale
  around_filter :set_timezone
  before_filter :set_conference
  before_filter :authenticate_user!
  before_filter :authorize_action
  before_action :configure_permitted_parameters, if: :devise_controller?

  AVATAR_SIZES = {
    mini: 24,
    normal: 48,
    bigger: 150
  }.with_indifferent_access

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"

    flash[:error] = t('flash.unauthorised')
    redirect_to :back rescue redirect_to root_path
  end

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def current_ability
    session = Session.find(params[:session_id]) if params[:session_id].present?
    reviewer = Reviewer.find(params[:reviewer_id]) if params[:reviewer_id].present?
    @current_ability ||= Ability.new(current_user, @conference, session, reviewer)
  end

  def default_url_options(options={})
    # Keep locale when navigating links if locale is specified
    params[:locale] && I18n.available_locales.include?(params[:locale].try(:to_sym)) ? { locale: params[:locale] } : {}
  end

  def sanitize(text)
    text.gsub(/[\s;'\"]/,'')
  end

  def sessions_by_track
    ([['Track', 'Submitted sessions']] +
      @conference.tracks.includes(:translated_contents).
        map {|track| [track.title, track.sessions.count]})
  end

  def sessions_by_type
    ([['Type', 'Submitted sessions']] +
      @conference.session_types.includes(:translated_contents).
        map {|type| [type.title, type.sessions.count]})
  end

  def gravatar_url(user, options={})
    options = options.with_indifferent_access
    gravatar_id = Digest::MD5::hexdigest(user.email).downcase
    size = options[:size] || :normal
    default = options[:default] || :mm
    "https://gravatar.com/avatar/#{gravatar_id}.png?s=#{AVATAR_SIZES[size]}&d=#{default}"
  end

  private

  def set_locale(&block)
    locales = [I18n.available_locales.first, current_user.try(:default_locale)]
    locales.push params[:locale] if params[:locale]
    begin
      I18n.with_locale(locales.pop, &block)
    rescue I18n::InvalidLocale => e
      if locales.size > 0
        flash.now[:error] = e.message
        retry
      else
        raise e
      end
    end
  end

  def set_timezone(&block)
    Time.use_zone(params[:time_zone], &block)
  end

  def set_conference
    @conference ||= (
      Conference.includes(tracks: [:translated_contents], session_types: [:translated_contents]).
        find_by_year(params[:year]) || Conference.current)
  end

  def authorize_action
    obj = resource rescue nil
    clazz = resource_class rescue nil
    action = params[:action].to_sym
    controller = obj || clazz || controller_name
    authorize!(action, controller)
  end

  def configure_permitted_parameters
    valid_registration_parameters = [
      :first_name, :last_name, :email, :wants_to_submit, :state,
      :organization, :website_url, :twitter_username, :default_locale,
      :phone, :country, :city, :bio
    ]
    devise_parameter_sanitizer.permit(:sign_up, keys: valid_registration_parameters)
    devise_parameter_sanitizer.permit(:account_update, keys: valid_registration_parameters)
  end

  def record_not_found
    respond_to do |format|
      format.html { render file: "#{Rails.root}/public/404", layout: false, status: 404 }
      format.js { render plain: '404 Not Found', status: 404 }
    end
  end
end
