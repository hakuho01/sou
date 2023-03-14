require 'discordrb'

require './framework/component'
require './service/twitter_open_service'
require './service/api_service'

class BotController < Component
  private

  def construct(bot)
    @api_service = ApiService.instance.init
  end

  public
  def handle_message(event, message_type)
    case message_type
    when :thumb
      @api_service.twitter_thumbnail(event)
    end
  end
end
