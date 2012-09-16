#!/usr/bin/env ruby
require "sinatra"
require 'rack-flash'
require 'parse-ruby-client'
Parse.init :application_id => ENV['APPLICATION_ID_IMESSGAE'],
           :api_key        => ENV['REST_API_KEY_IMESSGAE']

set :public_folder, File.dirname(__FILE__) + '/static'
enable :sessions
use Rack::Flash

helpers do
  def icon_class(index)
    index = index%10
    ['icon-fire','icon-globe','icon-briefcase','icon-fullscreen','icon-hand-up',
      'icon-hand-right','icon-certificate','icon-folder-open','icon-random',' icon-home'][index]
  end
end

get '/' do
  redirect "/rooms"
end

get '/index/:gender' do
  session[:gender] = params[:gender]
  redirect "/rooms"
end

get '/logout' do
  session.clear
  redirect "/rooms"
end
# TODO: show room just entered in rooms page
# TODO: link back to rooms
# TODO: give logout link in rooms page
get '/rooms' do
  page = params[:p] || 1
  params[:p] = page
  query = Parse::Query.new("Room")
  query.limit= 10
  query.skip = (page.to_i-1)*10
  puts "page=#{page}, limit=10, skip=#{(page.to_i-1)*10}"
  @rooms = query.get
  
  puts "@rooms.size = #{@rooms.size}"
  erb :rooms
end

get '/room/create' do
  erb :room_create
end

post '/room/create' do
  name = params[:name]
  password = params[:password]
  password_confirm = params[:password_confirm]
  
  if name.empty? || password.empty? || password_confirm.empty?
    flash[:notice] = "fields should not be empty"
    return erb :room_create
  end
  
  if password != password_confirm
     flash[:notice] = "password fields should equal"
    return erb :room_create
  else
    room1 = Parse::Object.new "Room", {
        "name" => name, "password" => password
    }
    room1.save
    puts room1
    redirect "/rooms"
  end
end

post '/room/enter' do
  room_id = params[:room_id]
  puts params.inspect
  password = params[:password]
  room = Parse::Query.new("Room").eq("objectId",room_id).eq("password", password).get
  puts "---------------"
  puts room.inspect
  puts "------END------"
  if room.nil? || room.empty?
    flash[:notice] = "Seems you have typed in wrong password"
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
    puts "You need password to enter this room"
    flash[:notice] = "You need password to enter this room"
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