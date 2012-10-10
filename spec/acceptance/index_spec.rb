require File.dirname(__FILE__) + '/spec_helper'

require 'crowdring/logging_service'

describe 'Filtering ringers', type: :request, js: true do

  before(:all) do
    @number = '+18001111111'
    @logging_service = Crowdring::LoggingService.new([@number])
    Crowdring::Server.service_handler.add('logging', @logging_service)
  end

  before(:each) do
    Capybara.app_host = 'http://localhost:5000'

    DataMapper.auto_migrate!
    @number2 = '+18002222222'
    @number3 = '+18003333333'
    @campaign = Crowdring::Campaign.create(title: 'title', introductory_response: Crowdring::IntroductoryResponse.create(default_message:'default'))
    @campaign.assigned_phone_numbers.create(phone_number: @number)
  end

  it 'Filtering ringers based on who has joined since the most recent broadcast' do
    origRinger = Crowdring::Ringer.create(phone_number: @number2)
    @campaign.memberships.create(ringer: origRinger, created_at: DateTime.now-2)
    @campaign.most_recent_broadcast = DateTime.now - 1
    newRinger = @campaign.ringers.create(phone_number: @number3)
   
    visit "/campaign/#{@campaign.id}"
    page.find("label[for=new1]").text.should match('1')

    within('#broadcast') do
      choose('new1')
      click_button('broadcastbutton')
    end

    @logging_service.last_broadcast[:to_numbers].should eq([@number3])
    Crowdring::Campaign.get(@campaign.id).new_memberships.count.should eq(0)
  end
end
