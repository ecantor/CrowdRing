require 'rubygems'
require 'twilio-rb'
require 'sinatra/base'
require 'sinatra/json'
require 'data_mapper'
require 'pusher'
require 'json'

require 'crowdring/campaign'
require 'crowdring/supporter'

module Crowdring
  class Server < Sinatra::Base
    helpers Sinatra::JSON

    configure do
      Twilio::Config.setup \
        account_sid: ENV["TWILIO_ACCOUNT_SID"],
        auth_token: ENV["TWILIO_AUTH_TOKEN"]

      Pusher.app_id = ENV["PUSHER_APP_ID"]
      Pusher.key = ENV["PUSHER_KEY"]
      Pusher.secret = ENV["PUSHER_SECRET"]
        
      DataMapper.setup(:default, 'sqlite::memory:')
      DataMapper.finalize
      DataMapper.auto_migrate!
      Crowdring::Campaign.create(phone_number: '+18143894106', title:'Test')
    end

    post '/smsresponse' do
      Campaign.get(params[:To]).supporters.first_or_create(phone_number: params[:From])
      Twilio::TwiML.build do |r|
        r.sms 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.', 
              from: params[:To], 
              to: params[:From]
      end
    end

    post '/voiceresponse' do
      Campaign.get(params[:To]).supporters.first_or_create(phone_number: params[:From])
      Twilio::TwiML.build do |r|
        r.sms 'Free Msg: Thanks for trying out @Crowdring, my global missed call campaigning tool.', 
              from: params[:To], 
              to: @phone_number
        r.reject reason: 'busy'
      end
    end

    get '/' do  
      @campaigns = Campaign.all

      erb :index
    end

    get '/supporters/:number' do 
      supporters =  Campaign.get(params[:number]).supporters.map {|s| s.phone_number}
      json supporters
    end

    get '/campaign/:number' do
      @supporters =  Campaign.get(params[:number]).supporters.map {|s| s.phone_number}

      erb :campaign
    end

    get '/campaign/new' do
      @numbers = Twilio::IncomingPhoneNumber.all.map {|n| n.phone_number}

      erb :campaign_new
    end

    post '/campaign/create' do
      Campaign.create(phone_number: params[:phone_number],
                      title: params[:title])
      
      redirect to('/')
    end

    post '/broadcast' do
      from = params[:number]
      message = params[:message]

      Campaign.get(from).supporters.each do |to|
        Twilio::SMS.create(to: to.phone_number, from: from,
                           body: message)
      end
      redirect to('/')
    end

    run! if app_file == $0
  end
end