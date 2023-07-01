# frozen_string_literal: true

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
    sleep 5
    event_msg_id = event.message.id.to_s
    event_msg_ch = event.message.channel.id.to_s
    return if event_msg_ch == '1113335713358938233' # 展開しないチャンネル

    uri = URI.parse("https://discord.com/api/channels/#{event_msg_ch}/messages/#{event_msg_id}")
    res = Net::HTTP.get_response(uri, 'Authorization' => "Bot #{TOKEN}")
    parsed_res = JSON.parse(res.body)
    return unless parsed_res['embeds'].empty? # discordが埋め込みやってなければ以下へ進む

    # ツイート情報を取得する
    content = event.message.content
    return if content.match(/\|\|http/) # 埋め込みがなくてもスポイラーなら展開しない

    twitter_urls = content.scan(%r{https://twitter.com/[a-zA-Z0-9_]+/status/[0-9]+})
    post_content = ""

    twitter_urls.each do |twitter_url|
      vx_twitter_url = twitter_url.to_s.insert(8,'vx')
      post_content = post_content + vx_twitter_url + "\n"
    end
    event.respond(post_content)
  end
end
