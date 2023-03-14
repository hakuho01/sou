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
    uri = URI.parse("https://discord.com/api/channels/#{event_msg_ch}/messages/#{event_msg_id}")
    res = Net::HTTP.get_response(uri, 'Authorization' => "Bot #{TOKEN}")
    parsed_res = JSON.parse(res.body)
    return unless parsed_res['embeds'].empty? # discordが埋め込みやってなければ以下へ進む

    # ツイート情報を取得する
    content = event.message.content
    return if content.match(/\|\|http/) # 埋め込みがなくてもスポイラーなら展開しない

    twitter_urls = content.scan(%r{https://twitter.com/[a-zA-Z0-9_]+/status/[0-9]+})

    twitter_urls.each do |twitter_url|
      twitter_id = twitter_url.to_s.match(%r{/status/[0-9]+}).to_s.slice!(8..-1)
      token = ENV['TWITTER_BEARER_TOKEN']
      client = SimpleTwitter::Client.new(bearer_token: token)
      response = client.get_raw("#{Constants::URLs::TWITTER}#{twitter_id}?tweet.fields=created_at,attachments,possibly_sensitive,public_metrics,entities&expansions=author_id,attachments.media_keys&user.fields=profile_image_url&media.fields=media_key,type,url")
      parsed_response = JSON.parse(response)

      # mediaがvideoでないか確認する
      next if parsed_response['includes']['media'][0]['type'] == 'video'

      likes = parsed_response['data']['public_metrics']['like_count']
      rts = parsed_response['data']['public_metrics']['retweet_count']
      footer_text = "#{likes} Favs, #{rts} RTs"
      author_name = parsed_response['includes']['users'][0]['name']
      author_icon = parsed_response['includes']['users'][0]['profile_image_url']
      author_url = "https://twitter.com/#{parsed_response['includes']['users'][0]['username']}"
      json_template = {
        "embeds": [
          {
            "url": twitter_url.to_s,
            "description": parsed_response['data']['text'],
            "author": {
              "name": author_name,
              "url": author_url,
              "icon_url": author_icon
            },
            "color": 0x1DA1F2,
            "footer": {
              "text": footer_text
            },
            "image": { "url": parsed_response['includes']['media'][0]['url'] }
          }
        ]
      }
      parsed_response['includes']['media'].each_with_index do |n, i|
        next if i.zero?

        json_template[:embeds].push({ "url": twitter_url, "image": { "url": n['url'] } })
        json_template[:embeds][0][:footer][:text] = "#{footer_text}, #{i + 1} images"
      end
      tweeted_time = Time.parse(parsed_response['data']['created_at'])
      jst_tweeted_time = Time.at(tweeted_time, in: '+09:00')
      jst_tweeted_time = jst_tweeted_time.strftime('%y年%m月%d日 %H:%M')
      json_template[:embeds][0][:footer][:text] = "#{json_template[:embeds][0][:footer][:text]}       #{jst_tweeted_time}"
      uri = URI.parse("https://discordapp.com/api/channels/#{event_msg_ch}/messages")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme === 'https'
      params = json_template
      headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bot #{TOKEN}" }
      response = http.post(uri.path, params.to_json, headers)
      response.code
      response.body
    end
  end
end