import { Component, PropTypes } from 'react';
import { connect }              from 'react-redux';

import Loading                  from '../application/loading.component';
import InfinitePagination       from '../pagination/infinite_pagination.component';
import OrderSelector            from '../order/order_selector.component';

import ActionPlansSidebar       from './action_plans_sidebar.component';
import ActionPlansList          from './action_plans_list.component';
import DownloadButton           from './download_button.component';
import ActionPlansHeader        from './action_plans_header.component';

import * as actions             from './action_plans.actions';
import { setOrder }             from '../order/order.actions';
import { getOrderByUrl }        from '../order/order.reducers';

class ActionPlans extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: true
    }
  }

  componentDidMount() {
    // Set weight as default order triggering a fetch action plans action
    this.props.setOrder(getOrderByUrl() || 'weight');
  }

  componentWillReceiveProps({ filters, order }) {
    if (this.props.filters !== filters || this.props.order !== order) {
      this.setState({ loading: true });
      this.props.fetchActionPlans({ 
        filters: filters || this.props.filters, 
        order: order || this.props.order, 
        seed: this.props.seed 
      });
    } else {
      this.setState({ loading: false });
    }
  }

  render() {
    return (
      <div>
        <ActionPlansHeader />

        <div className="wrap row">
          <div className="wrap row">
            <div className="small-12 medium-3 column">
              <ActionPlansSidebar />
            </div>

            <div className="small-12 medium-9 column">
              <Loading show={this.state.loading} list={true} />
              <h3 className="proposals-count">
                { I18n.t('components.action_plans.count', { count: this.props.count }) }
              </h3>
              <DownloadButton filters={this.props.filters} order={this.props.order} seed={this.props.seed}/>
              <OrderSelector 
                orderLinks={["weight", "random", "confidence_score", "participants"]} />
              <ActionPlansList actionPlans={this.props.actionPlans} />
              {this.renderInfinitePagination()}
            </div>
          </div>
        </div>
      </div>
    );
  }


  renderInfinitePagination() {
    let infinitePaginationActive = !this.state.loading && 
      this.props.pagination.current_page < this.props.pagination.total_pages;

    if (infinitePaginationActive) {
      return (
        <InfinitePagination 
          onVisible={() => this.props.appendActionPlansPage({ 
            filters: this.props.filters, 
            order: this.props.order,
            page: this.props.pagination.current_page + 1,
            seed: this.props.seed
          })} /> 
      );
    }

    return null;
  }
}

export default connect(
  ({ actionPlans, filters, order, pagination, seed, count }) => (
    { actionPlans, filters, order, pagination, seed, count }
  ),
  {
    ...actions,
    setOrder
  }
)(ActionPlans);

ActionPlans.propTypes = {
  filters: PropTypes.object.isRequired,
  order: PropTypes.string,
  seed: PropTypes.any,
  count: PropTypes.number,
  pagination: PropTypes.object,
  actionPlans: PropTypes.array,
  setOrder: PropTypes.func.isRequired,
  fetchActionPlans: PropTypes.func.isRequired,
  appendActionPlansPage: PropTypes.func.isRequired
};
