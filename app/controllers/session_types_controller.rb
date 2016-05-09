# encoding: UTF-8
class SessionTypesController < ApplicationController
  skip_before_filter :authenticate_user!, only: %i(index)
  respond_to :json, :html

  def index
    @session_types = resource_class.for_conference(@conference).includes(:translated_contents)
  end

  def create
    @session_type = resource_class.new(session_type_params)
    if @session_type.save
      send_success_response(t('flash.session_type.create.success'))
    else
      @tags = ActsAsTaggableOn::Tag.where('name like ? and (expiration_year IS NULL or expiration_year >= ?)', 'tags.%', @conference.year).to_a
      @new_track = Track.new(conference: @conference)
      @new_session_type = @session_type
      @new_audience_level = AudienceLevel.new(conference: @conference)
      @new_page = Page.new(conference: @conference)
      @conference.supported_languages.each do |code|
        @new_track.translated_contents.build(language: code)
        @new_audience_level.translated_contents.build(language: code)
        @new_page.translated_contents.build(language: code)
      end

      missing_langs = @conference.supported_languages - @new_session_type.translated_contents.map(&:language)
      missing_langs.each do |code|
        @new_session_type.translated_contents.build(language: code)
      end
      flash.now[:error] = 'Something went wrong'
      render template: 'conferences/edit'
    end
  end

  def update
    @session_type = resource_class.where(id: params[:id]).first
    if @session_type.update_attributes(session_type_params)
      send_success_response(t('flash.session_type.update.success'))
    else
      @tags = ActsAsTaggableOn::Tag.where('name like ? and (expiration_year IS NULL or expiration_year >= ?)', 'tags.%', @conference.year).to_a
      @new_track = Track.new(conference: @conference)
      @new_session_type = @session_type
      @new_audience_level = AudienceLevel.new(conference: @conference)
      @new_page = Page.new(conference: @conference)
      @conference.supported_languages.each do |code|
        @new_track.translated_contents.build(language: code)
        @new_audience_level.translated_contents.build(language: code)
        @new_page.translated_contents.build(language: code)
      end

      missing_langs = @conference.supported_languages - @new_session_type.translated_contents.map(&:language)
      missing_langs.each do |code|
        @new_session_type.translated_contents.build(language: code)
      end
      flash.now[:error] = 'Something went wrong'
      render template: 'conferences/edit'
    end
  end

  private
  def resource_class
    SessionType
  end

  def session_type_params
    allowed_params = []
    allowed_params << { valid_durations: [] } if @session_type.nil? || !@conference.visible?
    allowed_params << { translated_contents_attributes: %i(id language title content) }
    attrs = params.require(:session_type).permit(allowed_params)
    attrs = attrs.merge(conference_id: @conference.id)
    if attrs[:valid_durations]
      attrs[:valid_durations] = attrs[:valid_durations].map(&:to_i)
    end
    attrs
  end

  def send_success_response(notice)
    respond_with @session_type do |format|
       format.html {
         redirect_to conference_session_types_path(@conference), notice: notice
       }
       format.json {
         render json: {
           id: @session_type.id,
           valid_durations: @session_type.valid_durations,
           translations: @conference.languages.map do |l|
             I18n.with_locale(l[:code]) do
               {title: @session_type.title, description: @session_type.description, language: l }
             end
           end
         }
       }
     end
  end
end
