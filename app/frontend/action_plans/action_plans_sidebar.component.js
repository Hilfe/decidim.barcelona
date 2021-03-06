import ActionPlansFilters  from './action_plans_filters.component';
import NewActionPlanButton from './new_action_plan_button.component';

const ActionPlansSidebar = () => (
  <aside className="sidebar" role="complementary">
    <NewActionPlanButton />
    <div className="sidebar-section proposal-filter-menu collapsed">
      <h2 className="title">{I18n.t('proposals.index.filter.title')}<span className="toggle-menu"></span></h2>
      <div className="sidebar-section-content">
        <ActionPlansFilters />
      </div>
    </div>
  </aside>
);

export default ActionPlansSidebar;
