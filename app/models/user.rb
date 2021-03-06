class User < ActiveRecord::Base
  ROLES = %w{administrator moderator dynamizer reviewer reader}

  include Verification
  include PgSearch

  def ability
    @ability ||= Ability.new(self)
  end

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :async

  acts_as_voter
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  has_one :organization
  has_one :lock
  has_many :flags
  has_many :identities, dependent: :destroy
  has_many :debates, -> { with_hidden }, foreign_key: :author_id
  has_many :proposals, -> { with_hidden }, foreign_key: :author_id
  has_many :comments, -> { with_hidden }
  has_many :failed_census_calls
  has_many :notifications
  has_many :recommendations
  has_many :recommended_proposals, through: :recommendations, source: :proposal


  validates :username, presence: true, if: :username_required?
  validates :username, uniqueness: true, if: :username_required?
  validates :document_number, uniqueness: { scope: :document_type }, allow_blank: true

  validate :validate_username_length

  validates :official_level, inclusion: {in: 0..5}
  validates :terms_of_service, acceptance: { allow_nil: false }, on: :create

  validates :locale, inclusion: {in: I18n.available_locales.map(&:to_s),
                                 allow_nil: true}

  validates_associated :organization, message: false

  accepts_nested_attributes_for :organization, update_only: true

  attr_accessor :skip_password_validation

  scope :administrators, -> { where.contains(roles: ['administrator']) }
  scope :moderators,     -> { where.contains(roles: ['moderator']) }
  scope :reviewer,       -> { where.contains(roles: ['reviewer']) }
  scope :dynamizers,     -> { where.contains(roles: ['dynamizer']) }
  scope :organizations,  -> { joins(:organization) }
  scope :officials,      -> { where("official_level > 0") }
  scope :for_render,     -> { includes(:organization) }
  scope :by_document,    -> (document_type, document_number) { where(document_type: document_type, document_number: document_number) }

  before_validation :clean_document_number

  pg_search_scope :pg_search, {
                    against: {
                      document_number: 'A',
                      email: 'B',
                      username: 'C',
                      name: 'D'
                    },
                    ignoring: :accents,
                  }

  # Get the existing user by email if the provider gives us a verified email.
  def self.first_or_initialize_for_oauth(auth)
    oauth_email           = auth.info.email
    oauth_email_confirmed = oauth_email.present? && (auth.info.verified || auth.info.verified_email)
    oauth_user            = User.find_by(email: oauth_email) if oauth_email_confirmed
    devise_password_token = Devise.friendly_token[0,20]

    oauth_user || User.new(
      username:  auth.info.name || auth.uid,
      email: oauth_email,
      oauth_email: oauth_email,
      password: devise_password_token,
      password_confirmation: devise_password_token,
      terms_of_service: '1',
      confirmed_at: oauth_email_confirmed ? DateTime.now : nil,
      notifications_by_default: true,
      weekly_summary: true,
      email_on_comment: true,
      email_on_comment_reply: true
    )
  end

  def name
    organization? ? organization.name : username
  end

  def debate_votes(debates)
    voted = votes.for_debates(debates)
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def proposal_votes(proposals)
    voted = votes.for_proposals(proposals)
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def comment_flags(comments)
    comment_flags = flags.for_comments(comments)
    comment_flags.each_with_object({}){ |f, h| h[f.flaggable_id] = true }
  end

  def administrator?
    roles.include?('administrator')
  end

  def moderator?
    roles.include?('moderator')
  end

  def reviewer?
    roles.include?('reviewer')
  end

  def organization?
    organization.present?
  end

  def verified_organization?
    organization && organization.verified?
  end

  def official?
    official_level && official_level > 0
  end

  def add_official_position!(level = 0)
    update official_level: level.to_i
  end

  def remove_official_position!
    update official_level: 0
  end

  def block
    debates_ids = Debate.where(author_id: id).pluck(:id)
    comments_ids = Comment.where(user_id: id).pluck(:id)
    proposal_ids = Proposal.where(author_id: id).pluck(:id)

    self.hide

    Debate.hide_all debates_ids
    Comment.hide_all comments_ids
    Proposal.hide_all proposal_ids
  end

  def erase(erase_reason = nil)
    self.update(
      erased_at: Time.now,
      erase_reason: erase_reason,
      username: nil,
      email: nil,
      unconfirmed_email: nil,
      document_number: nil,
      phone_number: nil,
      encrypted_password: "",
      confirmation_token: nil,
      reset_password_token: nil,
      email_verification_token: nil
    )
  end

  def erased?
    erased_at.present?
  end

  def locked?
    Lock.find_or_create_by(user: self).locked?
  end

  def self.search(term)
    term.present? ? where("email = ? OR username ILIKE ?", term, "%#{term}%") : none
  end

  def self.username_max_length
    @@username_max_length ||= self.columns.find { |c| c.name == 'username' }.limit || 60
  end

  def show_welcome_screen?
    sign_in_count == 1 && unverified? && !organization && !administrator?
  end

  def password_required?
    return false if skip_password_validation
    super
  end

  def username_required?
    !organization? && !erased? && !registering_with_oauth
  end

  def email_required?
    !erased? && !registering_with_oauth
  end

  def has_official_email?
    domain = Setting['email_domain_for_officials']
    !email.blank? && ( (email.end_with? "@#{domain}") || (email.end_with? ".#{domain}") )
  end

  def locale
    self[:locale] ||= I18n.default_locale.to_s
  end

  def confirmation_required?
    super && !registering_with_oauth
  end

  def send_oauth_confirmation_instructions
    if oauth_email != email
      self.update(confirmed_at: nil)
      self.send_confirmation_instructions
    end
    self.update(oauth_email: nil) if oauth_email.present?
  end

  def save_requiring_finish_signup
    self.update(registering_with_oauth: true)
  end

  def save_requiring_finish_signup_without_email
    self.update(registering_with_oauth: true, email: nil)
  end

  def has_facebook_identity?
    return @has_facebook_identity if defined?(@has_facebook_identity)
    @has_facebook_identity = identities.detect{|i| i.provider == 'facebook'}.present?
  end

  private
    def clean_document_number
      self.document_number = self.document_number.gsub(/[^a-z0-9]+/i, "").upcase unless self.document_number.blank?
    end

    def validate_username_length
      validator = ActiveModel::Validations::LengthValidator.new(
        attributes: :username,
        maximum: User.username_max_length)
      validator.validate(self)
    end

end
