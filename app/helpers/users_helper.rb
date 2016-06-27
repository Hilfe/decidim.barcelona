module UsersHelper

  def humanize_document_type(document_type)
    case document_type
    when "dni"
      t "verification.residence.new.document_type.spanish_id"
    when "passport"
      t "verification.residence.new.document_type.passport"
    when "nie"
      t "verification.residence.new.document_type.residence_card"
    end
  end

  def comment_commentable_title(comment)
    commentable = comment.commentable
    if commentable.nil?
      deleted_commentable_text(comment)
    elsif commentable.hidden?
      "<abbr title='#{deleted_commentable_text(comment)}'>".html_safe +
      commentable.title +
      "</abbr>".html_safe
    else
      if commentable.respond_to? :participatory_process
        link_to(commentable.title, url_for({
          controller: commentable.class.name.downcase.pluralize,
          action: 'show',
          id: commentable.id,
          participatory_process_id: commentable.participatory_process
        }))
      else
        link_to(commentable.title, commentable)
      end
    end
  end

  def deleted_commentable_text(comment)
    case comment.commentable_type
    when "Proposal"
      t("users.show.deleted_proposal")
    when "Debate"
      t("users.show.deleted_debate")
    else
      t("users.show.deleted")
    end
  end

  def current_administrator?
    current_user && current_user.administrator?
  end

end
