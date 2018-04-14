require 'line/bot'
class LineClient

  ACCEPT_USERS = [
    'Uebc4ef7c800415f9b0127e9f8d557c3f'
  ].freeze

  #
  # 環境変数からトークンを取得して、クライアントの準備を行う
  #
  def initialize
    @client = Line::Bot::Client.new do |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    end
  end

  #
  # メッセージを返信する
  #
  def reply(text:)
    return unless ACCEPT_USERS.include? event['source']['userId']
    message = { type: 'text', text: text }
    @client.reply_message(event['replyToken'], message)
  end

  private
    #
    # /tmpに置いてあるファイルを元にイベントオブジェクトを生成する
    #
    def event
      return @event if @event
      event_json = Util.load_event_json
      @event = @client.parse_events_from(event_json)[0]
    end

end
