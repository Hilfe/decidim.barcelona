import { Component, PropTypes } from 'react';
import { connect }   from 'react-redux';

import * as actions  from '../order/order.actions';

class OrderSelector extends Component {
  render() {
    const { orderLinks, order, setOrder } = this.props;

    return (
      <section className="submenu">
        { 
          orderLinks.map(orderLink => {
            return (
              <a key={orderLink} onClick={() => setOrder(orderLink)} className={order === orderLink ? `${orderLink} active` : orderLink}>
                { I18n.t(`components.order_selector.${orderLink}`) }
              </a>
            );
          })
        }
      </section>
    );
  }
}

export default connect(
  ({ order }) => ({ order }),
  actions
)(OrderSelector);

OrderSelector.propTypes = {
  order: PropTypes.string.isRequired,
  orderLinks: PropTypes.array.isRequired,
  setOrder: PropTypes.func.isRequired
};
