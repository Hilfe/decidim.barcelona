import { Component, PropTypes } from 'react';
import {
  createStore,
  applyMiddleware,
  combineReducers
}                               from 'redux';
import { Provider }             from 'react-redux';
import ReduxPromise             from 'redux-promise';

import { actionPlan }           from './action_plans.reducers';
import categories               from '../categories/categories.reducers';
import districts                from '../districts/districts.reducers';
import filters                  from '../filters/filters.reducers';
import order                    from '../order/order.reducers';
import pagination               from '../pagination/pagination.reducers';

import ActionPlanShow           from './action_plan_show.component';

const middlewares = [ReduxPromise];

if (process.env.NODE_ENV === 'development') {
  const createLogger = require('redux-logger');
  const logger = createLogger();
  middlewares.push(logger);
}
const createStoreWithMiddleware = applyMiddleware(...middlewares)(createStore);

function createReducers(sessionState) {
  let session = function (state = sessionState) {
    return state;
  };

  return combineReducers({
    session,
    order,
    pagination,
    actionPlan,
    categories,
    districts,
    filters
  });
}

export default class ActionPlanApp extends Component {
  render() {
    return (
      <Provider 
        store={createStoreWithMiddleware(createReducers(this.props.session))}>
        <ActionPlanShow actionPlanId={this.props.actionPlanId} />
      </Provider>
    );
  }
}

ActionPlanApp.propTypes = {
  session: PropTypes.object.isRequired,
  actionPlanId: PropTypes.string.isRequired
};
