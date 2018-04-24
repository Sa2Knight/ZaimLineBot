require 'net/http'
require 'uri'
require 'json'
require 'date'

class ChatworkClient

  @@API_BASE = 'https://api.chatwork.com/v2'
  @@ROOM_ID  = '104044194'

  #
  # tokenを指定してオブジェクトを生成
  # tokenを省略した場合、環境変数を参照する
  #
  def initialize(token = nil)
    @token = token || ENV['CHATWORKAPI']
  end

  #
  # ルームに新規メッセージを送信
  # room_id: 対象のroomID
  # body:    投稿する本文
  #
  def sendMessage(body)
    url = '/rooms/' + @@ROOM_ID + '/messages'
    res = createHttpObject(url, :post, {:body => body})
    return res.body ? JSON.parse(res.body) : []
  end


  private

    # HTTPリクエストを送信する
    def createHttpObject(url, method, params = {})
      api_uri = URI.parse(@@API_BASE + url)
      https = Net::HTTP.new(api_uri.host, api_uri.port)
      https.use_ssl = true
      req = Net::HTTP::Post.new(api_uri.request_uri)
      req["X-ChatWorkToken"] = @token
      req.set_form_data(params)
      https.request(req)
    end

end
