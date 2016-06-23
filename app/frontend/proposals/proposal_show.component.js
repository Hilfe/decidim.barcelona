import { Component, PropTypes } from 'react';
import { connect }              from 'react-redux';

import * as actions             from './proposals.actions';

import Loading                  from '../application/loading.component';
import SocialShareButtons       from '../application/social_share_buttons.component';
import DangerLink               from '../application/danger_link.component';
import FilterMeta               from '../filters/filter_meta.component';
import FollowButton             from '../follows/follow_button.component';
import Comments                 from '../comments/comments.component';

import ProposalReviewer         from './proposal_reviewer.component';
import ProposalBadge            from './proposal_badge.component';
import ProposalInfoExtended     from './proposal_info_extended.component';
import ProposalVoteBox          from './proposal_vote_box.component';
import ProposalReferences       from './proposal_references.component';
import ProposalActionPlans      from './proposal_action_plans.component';
import ProposalMeetings         from './proposal_meetings.component';

import htmlToReact              from '../application/html_to_react';
import simpleFormat             from '../application/simple_format';

class ProposalShow extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: true
    }
  }

  componentDidMount() {
    const { fetchProposal } = this.props;

    fetchProposal(this.props.proposalId).then(() => {
      this.setState({ loading: false });
    });
  }

  render() {
    return (
      <div className="proposal-show component">
        <Loading show={this.state.loading} />
        {this.renderProposal()}
      </div>
    );
  }

  renderProposal() {
    const { proposal } = this.props;

    if (proposal.id) {
      const { 
        id,
        code,
        url, 
        title, 
        created_at, 
        official, 
        from_meeting, 
        author,
        summary,
        closed,
        voted,
        votable,
        total_votes,
        total_comments,
        scope_,
        district,
        category,
        subcategory,
        editable,
        conflictive,
        external_url,
        hidden,
        can_hide,
        can_hide_author,
        flagged
      } = proposal;

      return (
        <div>
          <div className={(hidden || author.hidden) ? 'row faded' : 'row'} id={`proposal_${proposal.id}`}>
            <div className="small-12 medium-9 column">
              <i className="icon-angle-left left"></i>&nbsp;

              <a className="left back" href="/proposals">
                {I18n.t('proposals.show.back_link')}
              </a>

              {this.renderEditButton(editable, url)}

              <h2>
                <a href={url}>{title}<ProposalBadge proposal={proposal} /></a>
              </h2>

              <div className="alert-box info radius margin-top">
                <strong>{ I18n.t("proposals.proposal.closing") }</strong>
              </div>

              {this.renderConflictiveWarning(conflictive)}

              <ProposalInfoExtended
                id={ id }
                code={ code }
                created_at={ created_at }
                official={ official }
                from_meeting={ from_meeting }
                author={ author }
                totalComments={ total_comments } 
                flagged={ flagged } />

              <div className="proposal-description">
                {htmlToReact(simpleFormat(summary))}
              </div>

              {this.renderExternalUrl(external_url)}

              <FilterMeta 
                scope={ scope_ }
                district={ district }
                category={ category }
                subcategory={ subcategory } 
                useServerLinks={ true }/>

              <ProposalReferences />

              <div className="js-moderator-proposal-actions margin">
                {this.renderHideButton(id, can_hide)}
                {this.renderHideAuthorButton(id, can_hide_author)}
                {this.renderBuildActionPlanButton(id)}
              </div>

              <ProposalActionPlans />

              <ProposalReviewer />
            </div>

            <aside className="small-12 medium-3 column">
              <div className="sidebar-divider"></div>
              <h3>{ I18n.t("votes.supports") }</h3>
              <ProposalVoteBox 
                hideButton={ closed }
                proposalId={ proposal.id } 
                proposalTitle={ title } 
                proposalUrl={ url } 
                voted={ voted } 
                votable={ votable } 
                totalVotes={ total_votes } 
                totalComments={ total_comments } />
              <FollowButton 
                followingId={id}
                followingType={'Proposal'} />
              <div className="sidebar-divider"></div>
              <h3>{ I18n.t("proposals.show.share") }</h3>
              <SocialShareButtons 
                title={ title }
                url={ url }/>
            </aside>
          </div>

          <ProposalMeetings useServerLinks={ true } />

          <Comments commentable={{...proposal, type: 'Proposal'}} />
        </div>
      );
    }
    return null;
  }

  renderEditButton(editable, url) {
    if (editable) {
      return (
        <a href={`${url}/edit`} className="edit-proposal button success tiny radius right">
          <i className="icon-edit"></i>
          { I18n.t("proposals.show.edit_proposal_link") }
        </a>
      );
    }

    return null;
  }

  renderHideButton(id, hasPermission) {
    const { hideProposal } = this.props;

    if (hasPermission) {
      return (
        <DangerLink onClick={() => hideProposal(id)}>
          { I18n.t('admin.actions.hide') }
        </DangerLink>
      );
    }
    return null;
  }

  renderHideAuthorButton(id, hasPermission) {
    const { hideProposalAuthor } = this.props;

    if (hasPermission) {
      return (
        <span>
          <span>&nbsp;|&nbsp;</span>
          <DangerLink onClick={() => hideProposalAuthor(id)}>
            { I18n.t('admin.actions.hide_author') }
          </DangerLink>
        </span>
      );
    }
    return null;
  }

  renderBuildActionPlanButton(id) {
    const { session, participatoryProcessId } = this.props;

    if (session.can_create_action_plan) {
      return (
        <span>
          <span>&nbsp;|&nbsp;</span>
          <a href={`/${participatoryProcessId}/action_plans/build_from_proposal?proposal_id=${id}`}>
            { I18n.t('admin.actions.build_action_plan') }
          </a>
        </span>
      );
    }
    return null;
  }

  renderConflictiveWarning(isConflictive) {
    if (isConflictive) {
      return (
        <div className="alert-box alert radius margin-top">
          <strong>{ I18n.t("proposals.show.flag") }</strong>
        </div>
      );
    }
    
    return null;
  }

  renderExternalUrl(externalUrl) {
    if (externalUrl) {
      return (
        <div className="document-link">
          { htmlToReact(simpleFormat(externalUrl)) }
        </div>
      );
    }

    return null;
  }
}

export default connect(
  ({ session, proposal, participatoryProcessId }) => ({ session, proposal, participatoryProcessId }),
  actions
)(ProposalShow);

ProposalShow.propTypes = {
  session: PropTypes.object.isRequired,
  proposalId: PropTypes.string.isRequired,
  proposal: PropTypes.object,
  fetchProposal: PropTypes.func.isRequired,
  hideProposal: PropTypes.func.isRequired,
  hideProposalAuthor: PropTypes.func.isRequired,
  participatoryProcessId: PropTypes.string.isRequired
};
