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

bot.message(contains: '<:0cb_3totsume:986725406105280582>') do |event|
  bot.send_message(channel_id=979757567200858183, "<@!#{event.user.id}>3凸目が終了したら https://discord.com/channels/612729411271131141/1112447156197007360 と https://discord.com/channels/612729411271131141/950253786897743883 で凸報告をお願いします:pray:\n今日もクラバトお疲れ様でした<:NGOD_saikouka:936573410836877372>")
end

bot.run
