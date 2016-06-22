require 'rails_helper'

feature "Notifications" do
  let(:participatory_process) { create :participatory_process }
  let(:author) { create :user }
  let(:user) { create :user }
  let(:debate) { create :debate, participatory_process: participatory_process, author: author }
  let(:proposal) { create :proposal, participatory_process: participatory_process, author: author }

  scenario "User commented on my debate", :js do
    login_as user
    visit debate_path debate, participatory_process_id: debate.participatory_process.slug

    fill_in "comment-body-root", with: "I commented on your debate"
    click_button "Publish comment"
    within "#comments" do
      expect(page).to have_content "I commented on your debate"
    end

    logout
    login_as author
    author.reload

    visit root_path

    find(".icon-notification").click

    expect(page).to have_css ".notification", count: 1

    expect(page).to have_content "Someone commented on"
    expect(page).to have_xpath "//a[@href='#{notification_path(Notification.last)}']"
  end

  scenario "Multiple comments on my proposal", :js do
    login_as user
    visit proposal_path(proposal, participatory_process_id: proposal.participatory_process.slug)

    fill_in "comment-body-root", with: "I agree"
    click_button "Publish comment"
    within "#comments" do
      expect(page).to have_content "I agree"
    end

    logout
    login_as create(:user)
    visit proposal_path(proposal, participatory_process_id: proposal.participatory_process.slug)

    fill_in "comment-body-root", with: "I disagree"
    click_button "Publish comment"
    within "#comments" do
      expect(page).to have_content "I disagree"
    end

    logout
    author.reload

    login_as author
    visit root_path

    find(".session-menu .icon-notification").click

    expect(page).to have_css ".notification", count: 1

    expect(page).to have_content "There are 2 new comments on"
    expect(page).to have_xpath "//a[@href='#{notification_path(Notification.last)}']"
  end

  scenario "User replied to my comment", :js do
    comment = create :comment, commentable: debate, user: author
    login_as user
    visit debate_path debate, participatory_process_id: debate.participatory_process.slug

    expect(page).to have_css("#comment_#{comment.id}")

    page.find('a.reply').click

    within "#comment_#{comment.id}" do
      fill_in "comment-body-#{comment.id}", with: "I replied to your comment"
      click_button "Publish reply"
    end

    within "#comment_#{comment.id}" do
      expect(page).to have_content "I replied to your comment"
    end

    logout
    login_as author
    author.reload

    visit root_path

    find(".icon-notification").click

    expect(page).to have_css ".notification", count: 1
    expect(page).to have_content "Someone replied to your comment on"
    expect(page).to have_xpath "//a[@href='#{notification_path(Notification.last)}']"
  end

  scenario "Multiple replies to my comment", :js do
    comment = create :comment, commentable: debate, user: author
    3.times do |n|
      login_as create(:user)
      visit debate_path debate, participatory_process_id: debate.participatory_process.slug

      page.find("#comment_#{comment.id} a.reply", match: :first).click

      within "#comment_#{comment.id}" do
        fill_in "comment-body-#{comment.id}", with: "Reply number #{n}"
        click_button "Publish reply"
      end

      within "#comment_#{comment.id}" do
        expect(page).to have_content "Reply number #{n}"
      end
      logout
    end

    login_as author
    author.reload

    visit root_path

    find(".icon-notification").click

    expect(page).to have_css ".notification", count: 1
    expect(page).to have_content "There are 3 new replies to your comment on"
    expect(page).to have_xpath "//a[@href='#{notification_path(Notification.last)}']"
  end

  scenario "Author commented on his own debate", :js do
    login_as author
    visit debate_path debate, participatory_process_id: debate.participatory_process.slug

    fill_in "comment-body-root", with: "I commented on my own debate"
    click_button "Publish comment"
    within "#comments" do
      expect(page).to have_content "I commented on my own debate"
    end

    find(".icon-no-notification").click
    expect(page).to have_css ".notification", count: 0
  end

  scenario "Author replied to his own comment", :js do
    comment = create :comment, commentable: debate, user: author
    login_as author
    visit debate_path debate, participatory_process_id: debate.participatory_process.slug

    expect(page).to have_css("#comment_#{comment.id}")

    page.find('a.reply').click

    within "#comment_#{comment.id}" do
      fill_in "comment-body-#{comment.id}", with: "I replied to my own comment"
      click_button "Publish reply"
    end

    within "#comment_#{comment.id}" do
      expect(page).to have_content "I replied to my own comment"
    end

    find(".icon-no-notification")

    visit notifications_path
    expect(page).to have_css ".notification", count: 0
  end

  context "mark as read" do

    scenario "mark a single notification as read" do
      user = create :user
      notification = create :notification, user: user

      login_as user
      visit notifications_path

      expect(page).to have_css ".notification", count: 1

      first(".notification a").click
      visit notifications_path

      expect(page).to have_css ".notification", count: 0
    end

    scenario "mark all notifications as read" do
      user = create :user
      2.times { create :notification, user: user }

      login_as user
      visit notifications_path

      expect(page).to have_css ".notification", count: 2
      click_link "Mark all as read"

      expect(page).to have_css ".notification", count: 0
      expect(current_path).to eq(notifications_path)
    end

  end

  scenario "no notifications" do
    login_as user
    visit notifications_path

    expect(page).to have_content "You don't have new notifications"
  end

end
