require './config/constants'
require './util/api_util'

require 'net/http'
require 'open-uri'
require 'openssl'
require 'cgi'
require 'simple_twitter'
require 'time'

class ApiService < Component
  # TwitterNSFWサムネイル表示
  def twitter_thumbnail(event)
    # discordが展開しているか確認する
    sleep 2
    event_msg_id = event.message.id.to_s
    event_msg_ch = event.message.channel.id.to_s

    uri = URI.parse("https://discord.com/api/channels/#{event_msg_ch}/messages/#{event_msg_id}")
    res = Net::HTTP.get_response(uri, 'Authorization' => "Bot #{TOKEN}")
    parsed_res = JSON.parse(res.body)
    return unless parsed_res['embeds'].empty? || parsed_res['embeds'][0]['title'] == 'X' # discordが埋め込みやってなければ以下へ進む

    # ツイート情報を取得する
    content = event.message.content
    return if content.match(/\|\|http/) # 埋め込みがなくてもスポイラーなら展開しない

    twitter_urls = content.scan(%r{(https://twitter.com/[a-zA-Z0-9_]+/status/[0-9]+)|(https://x.com/([a-zA-Z0-9_]+)/status/([0-9]+))})
    post_content = ''

    twitter_urls.each do |item|
      twitter_url = item.select { |e| e.to_s.match?(%r{https?://\S+})}
      vx_twitter_url = twitter_url[0].to_s[8, 1] == 't' ? twitter_url[0].to_s.insert(8, 'vx') : twitter_url[0].to_s.sub(/x.com/, 'vxtwitter.com')
      post_content = post_content << vx_twitter_url << "\n"
    end
    event.respond(post_content)
  end
end
