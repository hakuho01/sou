require 'discordrb'
require 'dotenv'
require 'pg'
require 'sequel'
require 'date'

require './controller/bot_controller'

Dotenv.load
TOKEN = ENV['TOKEN']
CLIENT_ID = ENV['CLIENT_ID'].to_i
POSTGRES_URL = ENV['POSTGRES_URL']

bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix:'!sou ', discord_api_version: 9
bot_controller = BotController.instance.init(bot)

DB = Sequel.connect(POSTGRES_URL)

# TwiiterのNSFWサムネイル表示
bot.message(contains: %r{https://twitter.com/([a-zA-Z0-9_]+)/status/([0-9]+)|https://x.com/([a-zA-Z0-9_]+)/status/([0-9]+)}) do |event|
  bot_controller.handle_message(event, :thumb)
end

bot.message(contains: '<:0cb_3totsume:986725406105280582>') do |event|
  bot.send_message(channel_id=979757567200858183, "<@!#{event.user.id}>3凸目が終了したら https://discord.com/channels/612729411271131141/950253786897743883 で凸報告をお願いします:pray:\n今日もクラバトお疲れ様でした<:NGOD_saikouka:936573410836877372>") if event.channel.category.id === 1132553442502656040
end

# リマインダー機能
bot.heartbeat do
  now = Time.now
  unexecuted_tasks = DB[:reminder].where(executed: false)
  notifications = unexecuted_tasks.where { datetime <= now }
  notifications.all.each do |notification|
    bot.send_message(channel_id=notification[:channel].to_i, "<@!#{notification[:user_id]}> #{notification[:text]}")
    DB[:reminder].where(id: notification[:id]).update(executed: true)
  end
end

bot.command :remind do |event|
  words = event.message.to_s.split(' ')
  datetime = DateTime.parse(words[2].gsub(/\//,'-') << ' ' << words[3]) - Rational('9/24')
  user_id = event.user.id
  text = words[4].delete('`')
  channel_id = event.channel.id
  DB[:reminder].insert(datetime: datetime, executed: false, user_id: user_id, text: text, channel: channel_id)
  event.respond('リマインダー登録完了。')
end

bot.run
