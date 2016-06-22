require 'rails_helper'

feature 'Moderate proposals' do
  let(:participatory_process) { create(:participatory_process) }

  scenario 'Hide', :js do
    citizen = create(:user)
    moderator = create(:moderator)

    proposal = create(:proposal, participatory_process: participatory_process)

    login_as(moderator)
    visit proposal_path(proposal, participatory_process_id: proposal.participatory_process.slug)

    expect(page).to have_selector("#proposal_#{proposal.id}")
    find("#proposal_#{proposal.id} a", text: "Hide").click

    login_as(citizen)
    visit proposals_path

    expect(page).to have_css('.proposal', count: 0)
  end

  scenario 'Can not hide own proposal', :js do
    moderator = create(:moderator)
    proposal = create(:proposal, participatory_process: participatory_process, author: moderator)

    login_as(moderator)
    visit proposal_path(proposal, participatory_process_id: proposal.participatory_process.slug)

    within("#proposal_#{proposal.id}") do
      expect(page).to_not have_link('Hide')
      expect(page).to_not have_link('Block author')
    end
  end

  feature '/moderation/ screen' do

    background do
      moderator = create(:moderator)
      login_as(moderator)
    end

    feature 'moderate in bulk' do
      feature "When a proposal has been selected for moderation" do
        background do
          @proposal = create(:proposal)
          visit moderation_proposals_path
          within('.sub-nav') do
            click_link "All"
          end

          within("#proposal_#{@proposal.id}") do
            check "proposal_#{@proposal.id}_check"
          end

          expect(page).to_not have_css("proposal_#{@proposal.id}")
        end

        scenario 'Hide the proposal' do
          click_on "Hide proposals"
          expect(page).to_not have_css("proposal_#{@proposal.id}")
          expect(@proposal.reload).to be_hidden
          expect(@proposal.author).to_not be_hidden
        end

        scenario 'Block the author' do
          click_on "Block authors"
          expect(page).to_not have_css("proposal_#{@proposal.id}")
          expect(@proposal.reload).to be_hidden
          expect(@proposal.author).to be_hidden
        end

        scenario 'Ignore the proposal' do
          click_button "Mark as viewed"
          expect(page).to_not have_css("proposal_#{@proposal.id}")
          expect(@proposal.reload).to be_ignored_flag
          expect(@proposal.reload).to_not be_hidden
          expect(@proposal.author).to_not be_hidden
        end
      end

      scenario "select all/none", :js do
        create_list(:proposal, 2)

        visit moderation_proposals_path

        within('.js-check') { click_on 'All' }

        all('input[type=checkbox]').each do |checkbox|
          expect(checkbox).to be_checked
        end

        within('.js-check') { click_on 'None' }

        all('input[type=checkbox]').each do |checkbox|
          expect(checkbox).to_not be_checked
        end
      end

      scenario "remembering page, filter and order" do
        create_list(:proposal, 52)

        visit moderation_proposals_path(filter: 'all', page: '2', order: 'created_at')

        click_button "Mark as viewed"

        expect(page).to have_selector('.js-order-selector[data-order="created_at"]')

        expect(current_url).to include('filter=all')
        expect(current_url).to include('page=2')
        expect(current_url).to include('order=created_at')
      end
    end

    scenario "Current filter is properly highlighted" do
      visit moderation_proposals_path
      expect(page).to_not have_link('Pending')
      expect(page).to have_link('All')
      expect(page).to have_link('Mark as viewed')

      visit moderation_proposals_path(filter: 'all')
      within('.sub-nav') do
        expect(page).to_not have_link('All')
        expect(page).to have_link('Pending review')
        expect(page).to have_link('Mark as viewed')
      end

      visit moderation_proposals_path(filter: 'pending_flag_review')
      within('.sub-nav') do
        expect(page).to have_link('All')
        expect(page).to_not have_link('Pending')
        expect(page).to have_link('Mark as viewed')
      end

      visit moderation_proposals_path(filter: 'with_ignored_flag')
      within('.sub-nav') do
        expect(page).to have_link('All')
        expect(page).to have_link('Pending review')
        expect(page).to_not have_link('Marked as viewed')
      end
    end

    scenario "Filtering proposals" do
      create(:proposal, title: "Regular proposal")
      create(:proposal, :flagged, title: "Pending proposal")
      create(:proposal, :hidden, title: "Hidden proposal")
      create(:proposal, :flagged, :with_ignored_flag, title: "Ignored proposal")

      visit moderation_proposals_path(filter: 'all')
      expect(page).to have_content('Regular proposal')
      expect(page).to have_content('Pending proposal')
      expect(page).to_not have_content('Hidden proposal')
      expect(page).to have_content('Ignored proposal')

      visit moderation_proposals_path(filter: 'pending_flag_review')
      expect(page).to_not have_content('Regular proposal')
      expect(page).to have_content('Pending proposal')
      expect(page).to_not have_content('Hidden proposal')
      expect(page).to_not have_content('Ignored proposal')

      visit moderation_proposals_path(filter: 'with_ignored_flag')
      expect(page).to_not have_content('Regular proposal')
      expect(page).to_not have_content('Pending proposal')
      expect(page).to_not have_content('Hidden proposal')
      expect(page).to have_content('Ignored proposal')
    end

    scenario "sorting proposals" do
      create(:proposal, title: "Flagged proposal", created_at: Time.now - 1.day, flags_count: 5)
      create(:proposal, title: "Flagged newer proposal", created_at: Time.now - 12.hours, flags_count: 3)
      create(:proposal, title: "Newer proposal", created_at: Time.now)

      visit moderation_proposals_path(order: 'created_at')

      expect("Flagged newer proposal").to appear_before("Flagged proposal")

      visit moderation_proposals_path(order: 'flags')

      expect("Flagged proposal").to appear_before("Flagged newer proposal")

      visit moderation_proposals_path(filter: 'all', order: 'created_at')

      expect("Newer proposal").to appear_before("Flagged newer proposal")
      expect("Flagged newer proposal").to appear_before("Flagged proposal")

      visit moderation_proposals_path(filter: 'all', order: 'flags')

      expect("Flagged proposal").to appear_before("Flagged newer proposal")
      expect("Flagged newer proposal").to appear_before("Newer proposal")
    end
  end
end
