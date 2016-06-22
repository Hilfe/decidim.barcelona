import { Component, PropTypes }   from 'react';
import { connect }                from 'react-redux';

import Loading                    from '../application/loading.component';

import ProposalsAutocompleteInput from '../proposals/proposals_autocomplete_input.component';
import ProposalsTable             from './proposals_table.component';

import * as actions               from './action_plans.actions';

class ActionPlanProposals extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: true
    }
  }

  componentDidMount() {
    const { actionPlan, fetchActionPlanProposals } = this.props;

    fetchActionPlanProposals(actionPlan.id).then(() => {
      this.setState({ loading: false });
    });
  }

  render() {
    const { editable, actionPlan, removeActionPlanProposal } = this.props;
    const { id } = actionPlan;
    const actionPlansProposals = actionPlan.actionPlansProposals || [];

    return (
      <div className="action-plan-proposals-component">
        <h2>{I18n.t("components.action_plan_proposals.title")}</h2>
        {this.renderSearchProposalsInput(id, actionPlansProposals)}
        <Loading show={this.state.loading} />
        <ProposalsTable 
          actionPlansProposals={ actionPlansProposals }
          onRemoveProposal={proposal => removeActionPlanProposal(id, proposal)} 
          editable={editable} />
      </div>
    );
  }

  renderSearchProposalsInput(id, actionPlansProposals) {
    const {editable, addActionPlanProposal, participatoryProcessId} = this.props;

    if (editable) {
      return (
        <ProposalsAutocompleteInput 
          proposalsApiUrl={`/api/proposals?participatory_process_id=${participatoryProcessId}`}
          excludeIds={actionPlansProposals.map(a => a.proposal.id)}
          onAddProposal={proposal => addActionPlanProposal(id, proposal)} />
      );
    }

    return null;
  }
}

export default connect(
  ({ participatoryProcessId }) => ({ participatoryProcessId }),
  actions
)(ActionPlanProposals);

ActionPlanProposals.propTypes = {
  actionPlan: PropTypes.object,
  participatoryProcessId: PropTypes.string.isRequired,
  fetchActionPlanProposals: PropTypes.func.isRequired,
  editable: PropTypes.bool,
  removeActionPlanProposal: PropTypes.func.isRequired,
  addActionPlanProposal: PropTypes.func.isRequired
};
