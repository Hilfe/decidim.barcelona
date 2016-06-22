class ActionPlanSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :created_at, :url, :scope_, :district,
    :edit_url, :new_revision_url, :approved, :weight, :social_media_image_url,
    :statistics

  has_one :category
  has_one :subcategory

  # Name collision with serialization `scope`
  def scope_
    object.scope
  end

  def url
    action_plan_path(object, participatory_process_id: object.participatory_process.slug)
  end

  def edit_url
    edit_action_plan_path(object)
  end

  def new_revision_url
    new_action_plan_revision_path(object)
  end

  def created_at
    I18n.l object.created_at.to_date
  end

  def district
    District.find(object.district)
  end

  def social_media_image_url
    scope && scope.asset_url('social-media-icon.png')
  end
end
