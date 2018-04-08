require 'oauth'
require 'date'

class ZaimClient
  API_URL = 'https://api.zaim.net/v2/'.freeze
  POCKET_MONEY = 50000

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
  end

  #
  # 収入の一覧を取得する
  # 期間の指定がない場合、今月を対象にする
  #
  def fetch_incomes(option = {})
    params = {
      mode: 'income'
    }.merge(Util.get_month_hash(Date.today))
     .merge(option)
    fetch_moneys(params)
  end

  #
  # 支出の一覧を取得する
  # 期間の指定がない場合、本日を対象にする
  # HACK: fetch_incomesと一緒やん
  #
  def fetch_payments(option = {})
    params = {
      mode: 'payment',
      start_date: Date.today.to_s,
      end_date:   Date.today.to_s
    }.merge(option)
    fetch_moneys(params)
  end

  #
  # 公費の一覧を取得する
  # 期間の指定がない場合、本日を対象にする
  #
  def fetch_public_payments(option = {})
    moneys = fetch_payments(option)
    return select_public_payments(moneys)
  end

  #
  # 私費の一覧を取得する
  # 期間の指定がない場合、本日を対象にする
  #
  def fetch_private_payments(option = {})
    moneys = fetch_payments(option)
    return select_private_payments(moneys)
  end

  #
  # 当該月の公費残額を取得する
  #
  def fetch_month_public_budget(date)
    month_hash = Util.get_month_hash(date)
    payments = self.fetch_public_payments(month_hash)
    incomes  = self.fetch_incomes(month_hash)

    budget = get_total_amount(incomes)\
               - get_total_amount(payments)\
               - POCKET_MONEY
    return budget
  end

  #
  # 当該月の私費残額を確認する
  #
  def fetch_month_private_budget(date)
    month_hash = Util.get_month_hash(date)
    payments = self.fetch_private_payments(month_hash)
    budget = POCKET_MONEY - get_total_amount(payments)
    return budget
  end

  #
  # 支払い一覧から、金額の合計を取得する
  #
  def get_total_amount(moneys)
    moneys.reduce(0) { |sum, acm| sum += acm['amount'] }
  end

  private

    #
    # 支払い一覧から、コメントに「公費」を含むものを取り出す
    #
    def select_public_payments(moneys)
      moneys.select do |money|
        money['mode'] == 'payment' && money['comment'].index('公費')
      end
    end

    #
    # 支払い一覧から、コメントに「私費」を含むものを取り出す
    # HACK: select_public_paymentsと一緒やん
    #
    def select_private_payments(moneys)
      moneys.select do |money|
        money['mode'] == 'payment' && money['comment'].index('私費')
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
