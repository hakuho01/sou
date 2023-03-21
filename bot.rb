require 'discordrb'
require 'dotenv'

require './controller/bot_controller'

Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID'].to_i

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix:'!sou ', discord_api_version: 9
bot_controller = BotController.instance.init(bot)

# TwiiterのNSFWサムネイル表示
bot.message(contains: %r{https://twitter.com/([a-zA-Z0-9_]+)/status/([0-9]+)}) do |event|
  bot_controller.handle_message(event, :thumb)
end

bot.run