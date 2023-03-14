require 'discordrb'
require 'dotenv'

Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID'].to_i

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix:'!sou '

bot.command :hello do |event|
 event.send_message("hello,world.#{event.user.name}")
end

bot.run