require "application_responder"

class ApplicationController < ActionController::Base
  include HasFilters
  include HasOrders

  before_action :authenticate_http_basic, if: :http_basic_auth_site?

  before_action :ensure_signup_complete
  before_action :set_locale
  before_action :track_email_campaign
  before_action :set_return_url

  helper_method :suggest_email_notifications?

  check_authorization unless: :devise_controller?
  self.responder = ApplicationResponder

  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html { redirect_to main_app.root_url, alert: exception.message }
      format.json { render json: {error: exception.message}, status: :forbidden }
    end
  end

  rescue_from FeatureFlags::FeatureDisabled do |exception|
    if Rails.env.production?
      raise ActionController::RoutingError.new('Not Found')
    else
      raise exception
    end
  end

  layout :set_layout
  respond_to :html

  private

    def authenticate_http_basic
      authenticate_or_request_with_http_basic do |username, password|
        username == Rails.application.secrets.http_basic_username && password == Rails.application.secrets.http_basic_password
      end
    end

    def http_basic_auth_site?
      !Rails.application.secrets.http_basic_username.blank?
    end

    def verify_lock
      if current_user.locked?
        redirect_to account_path, alert: t('verification.alert.lock')
      end
    end

    def set_locale
      if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
        session[:locale] = params[:locale]
      end

      session[:locale] ||= I18n.default_locale

      locale = session[:locale]

      if current_user
        current_user.locale = locale
        current_user.save
      end

      I18n.locale = locale
    end

    def set_layout
      if devise_controller?
        "devise"
      else
        "application"
      end
    end

    def set_debate_votes(debates)
      @debate_votes = current_user ? current_user.debate_votes(debates) : {}
    end

    def set_proposal_votes(proposals)
      @proposal_votes = current_user ? current_user.proposal_votes(proposals) : {}
    end

    def set_comment_flags(comments)
      @comment_flags = current_user ? current_user.comment_flags(comments) : {}
    end

    def ensure_signup_complete
      if user_signed_in? &&
        current_user.registering_with_oauth &&
        %w(finish_signup do_finish_signup).exclude?(action_name)
        redirect_to finish_signup_path
      end
    end

    def verify_resident!
      unless current_user.residence_verified?
        redirect_to new_residence_path, alert: t('verification.residence.alert.unconfirmed_residency')
      end
    end

    def verify_verified!
      if current_user.level_three_verified?
        redirect_to(account_path, notice: t('verification.redirect_notices.already_verified'))
      end
    end

    def track_email_campaign
      if params[:track_id]
        campaign = Campaign.where(track_id: params[:track_id]).first
        ahoy.track campaign.name if campaign.present?
      end
    end

    def set_return_url
      if !devise_controller? && controller_name != 'welcome' && is_navigational_format?
        store_location_for(:user, request.path)
      end
    end

    def suggest_email_notifications?
      return false unless current_user

      $redis.sismember("email_notifications_reminder", current_user.id.to_s)
    end

    def load_participation_process
      if params[:participatory_process_id].present?
        @participatory_process_id = params[:participatory_process_id]
        @participatory_process = ParticipatoryProcess.find(params[:participatory_process_id])
      else
        default_participatory_process_id = ParticipatoryProcess.first.slug
        redirect_to url_for(params.merge(participatory_process_id: default_participatory_process_id))
      end
    end
end
