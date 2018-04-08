require 'oauth'
require 'date'

class ZaimClient
  API_URL = 'https://api.zaim.net/v2/'.freeze

  #
  # ZaimAPIへのアクセストークンを生成する
  #
  def initialize
    oauth_params = {
      site:               'https://api.zaim.net',
      request_token_path: '/v2/auth/request',
      authorize_url:      'https://auth.zaim.net/users/auth',
      access_token_path:  'https://api.zaim.net'
    }
    @consumer = OAuth::Consumer.new(
      ENV['ZAIM_KEY'], ENV['ZAIM_SECRET'], oauth_params
    )
    @access_token = OAuth::AccessToken.new(
      @consumer, ENV['ZAIM_TOKEN'], ENV['ZAIM_TOKEN_SECRET']
    )
    @moneys = []
  end

  #
  # 日付を指定して本日の公費を取得する
  #
  def fetch_public_payments(date: Date.today)
    params = {
      mode: 'payment',
      start_date: date.to_s,
      end_date: date.to_s
    }
    @moneys = fetch_moneys(params)
    @moneys = select_public_payments
  end

  #
  # 支払い一覧から、金額の合計を取得する
  #
  def get_total_amount
    @moneys.reduce(0) { |sum, acm| sum += acm['amount'] }
  end

  private

    #
    # 支払い一覧から、コメントに「公費」を含むものを取り出す
    #
    def select_public_payments
      @moneys.select do |money|
        money['mode'] == 'payment' && money['comment'].index('公費')
      end
    end

    #
    # 全入力情報をAPIから取得する
    #
    def fetch_moneys(params = {})
      url = 'home/money'
      response = get(url, params)
      response['money'] if response
    end

    #
    # 指定したURLにリクエストを送信し、レスポンスをJSONデシリアライズ
    #
    def get(url, params = {})
      uri = Util.url_with_query_string(url, params)
      response = @access_token.get("#{API_URL}#{uri}")
      JSON.parse(response.body)
    end
end
