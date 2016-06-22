# coding: utf-8
require 'rails_helper'

feature 'Tags' do
  let(:participatory_process) { create(:participatory_process) }

  scenario 'Index' do
    earth = create(:debate, participatory_process: participatory_process, tag_list: 'Medio Ambiente')
    money = create(:debate, participatory_process: participatory_process, tag_list: 'Economía')

    visit debates_path

    within "#debate_#{earth.id}" do
      expect(page).to have_content "Medio Ambiente"
    end

    within "#debate_#{money.id}" do
      expect(page).to have_content "Economía"
    end
  end

  scenario 'Filtered' do
    debate1 = create(:debate, participatory_process: participatory_process, tag_list: 'Salud')
    debate2 = create(:debate, participatory_process: participatory_process, tag_list: 'salud')
    debate3 = create(:debate, participatory_process: participatory_process, tag_list: 'Hacienda')
    debate4 = create(:debate, participatory_process: participatory_process, tag_list: 'Hacienda')

    visit debates_path
    first(:link, 'Salud').click

    within("#debates") do
      expect(page).to have_css('.debate', count: 2)
      expect(page).to have_content(debate1.title)
      expect(page).to have_content(debate2.title)
      expect(page).to_not have_content(debate3.title)
      expect(page).to_not have_content(debate4.title)
    end

    visit debates_path(tag: 'salud')

    within("#debates") do
      expect(page).to have_css('.debate', count: 2)
      expect(page).to have_content(debate1.title)
      expect(page).to have_content(debate2.title)
      expect(page).to_not have_content(debate3.title)
      expect(page).to_not have_content(debate4.title)
    end
  end

  scenario 'Show' do
    debate = create(:debate, participatory_process: participatory_process, tag_list: 'Hacienda, Economía')

    visit debate_path(debate, participatory_process_id: debate.participatory_process.slug)

    expect(page).to have_content "Economía"
    expect(page).to have_content "Hacienda"
  end

  scenario 'Tag Cloud' do
    1.times  { create(:debate, participatory_process: participatory_process, tag_list: 'Medio Ambiente') }
    5.times  { create(:debate, participatory_process: participatory_process, tag_list: 'Corrupción') }
    5.times  { create(:debate, participatory_process: participatory_process, tag_list: 'Educación') }
    10.times { create(:debate, participatory_process: participatory_process, tag_list: 'Economía') }

    visit debates_path

    within(:css, "#tag-cloud") do
      expect(page.find("a:eq(1)")).to have_content("Economía (10)")
      expect(page.find("a:eq(2)")).to have_content("Corrupción (5)")
      expect(page.find("a:eq(3)")).to have_content("Educación (5)")
      expect(page.find("a:eq(4)")).to have_content("Medio Ambiente (1)")
    end
  end

  scenario 'Create', :js do
    user = create(:user, :official)
    login_as(user)

    visit new_debate_path(participatory_process_id: participatory_process.slug)
    fill_in 'debate_title', with: 'Title'
    fill_in_editor 'debate_description', with: 'Description'
    check 'debate_terms_of_service'

    fill_in 'debate_tag_list', with: "Impuestos, Economía, Hacienda"

    click_button 'Start a debate'

    expect(page).to have_content 'Debate created successfully.'
    expect(page).to have_content 'Economía'
    expect(page).to have_content 'Hacienda'
    expect(page).to have_content 'Impuestos'
  end

  scenario 'Create with too many tags', :js do
    user = create(:user, :official)
    login_as(user)

    visit new_debate_path(participatory_process_id: participatory_process.slug)
    fill_in 'debate_title', with: 'Title'
    fill_in_editor 'debate_description', with: 'Description'
    check 'debate_terms_of_service'

    fill_in 'debate_tag_list', with: "Impuestos, Economía, Hacienda, Sanidad, Educación, Política, Igualdad"

    click_button 'Start a debate'

    expect(page).to have_content error_message
    expect(page).to have_content 'tags must be less than or equal to 6'
  end

  scenario 'Update' do
    debate = create(:debate, participatory_process: participatory_process, tag_list: 'Economía')

    login_as(debate.author)
    visit edit_debate_path(debate, participatory_process_id: debate.participatory_process.slug)

    expect(page).to have_selector("input[value='Economía']")

    fill_in 'debate_tag_list', with: "Economía, Hacienda"
    click_button 'Save changes'

    expect(page).to have_content 'Debate updated successfully.'
    within('.tags') do
      expect(page).to have_css('a', text: 'Economía')
      expect(page).to have_css('a', text: 'Hacienda')
    end
  end

  scenario 'Delete' do
    debate = create(:debate, participatory_process: participatory_process, tag_list: 'Economía')

    login_as(debate.author)
    visit edit_debate_path(debate, participatory_process_id: debate.participatory_process.slug)

    fill_in 'debate_tag_list', with: ""
    click_button 'Save changes'

    expect(page).to have_content 'Debate updated successfully.'
    expect(page).to_not have_content 'Economía'
  end

end
