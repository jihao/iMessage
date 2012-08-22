#!/usr/bin/env ruby
require "sinatra"
require 'parse-ruby-client'
Parse.init :application_id => ENV['APPLICATION_ID_IMESSGAE'],
           :api_key        => ENV['REST_API_KEY_IMESSGAE']

set :public_folder, File.dirname(__FILE__) + '/static'
enable :sessions
           
get '/' do
  erb :index
end
get '/index/:gender' do
  session[:gender] = params[:gender]
  redirect "/rooms"
end

get '/rooms' do
  query = Parse::Query.new("Room")
  query.limit= 10
  @rooms = query.get
  puts @rooms.size
  "@rooms.size = #{@rooms.size}"
  erb :rooms
end

post '/room/create' do
  name = params[:name]
  password = params[:password]
  room1 = Parse::Object.new "Room", {
      "name" => 1337, "password" => "123456"
  }
  room1.save
  puts room1
  "OK"
end

post '/room/enter' do
  room_id = params[:room_id]
  password = params[:password]
  room = Parse::Query.new("Room").eq("objectId",room_id).eq("password", password).get
  if room.nil?
    puts "FAILED TO ENTER"
    redirect "/rooms"
  else
    session[:room_id] = room_id 
    redirect "/iMessage/#{room_id}"
  end
end

post '/iMessage' do
  room_id = params[:room_id]
  gender = session[:gender]
  message = params[:message]
  msg = Parse::Object.new "Message", {
      "room_id" => room_id,
      "gender" => gender, 
      "message" => message
  }
  msg.save
  redirect "/iMessage/#{room_id}"
end
get '/iMessage/:room_id' do
  if session[:room_id] != params[:room_id]
    puts "You have to type password to enter this room"
    redirect "/rooms"
  else
    query = Parse::Query.new("Message")
    query.limit = 20
    query.skip = (params[:page].to_i * 20) if params[:page]
    query.order_by = "createdAt"
    query.order = :descending
    @messages = query.eq("room_id",params[:room_id]).get
    puts "messages size=#{@messages.size}"
    erb :imessage
  end
  
end