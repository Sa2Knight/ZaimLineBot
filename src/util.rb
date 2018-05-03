require_relative 'chatwork_client'
class Util

  EVENT_JSON_PATH = '/tmp/line_zime/event.json'
  LOG_FILE_PATH   = 'logs'

  #
  # URLとクエリストリング用のパラメータを指定してフルURIを生成する
  #
  def self.url_with_query_string(url, params = nil)
    return url unless params
    url += '?'
    url += params.map { |k, v| "#{k}=#{v}" }.join('&')
    return url
  end

  #
  # Dateオブジェクトを渡して、その月の初日と最終日を含んだハッシュを戻す
  #
  def self.get_month_hash(date)
    {
      start_date: Date.new(date.year, date.month, 1),
      end_date:   Date.new(date.year, date.month, -1)
    }
  end

  #
  # /tmpに置いてあるファイルを開く
  #
  def self.load_event_json(parse: false)
    self.load_file(filename: EVENT_JSON_PATH, parse_json: parse)
  end

  #
  # /tmpに置いてあるファイルを元にメッセージを取得する
  #
  def self.get_event_message
    json = self.load_event_json(parse: true)
    json['events'][0]['message']['text']
  end

  #
  # ログをファイルに出力する
  #
  def self.write_log(text, with_chatwork: true)
    log = "【#{Time.now}】 #{text}"
    self.write_to_file(text: log, filename: LOG_FILE_PATH, append_mode: true)
    ChatworkClient.new.sendMessage(log) if with_chatwork
  end

  #
  # ファイルを読み込む
  #
  def self.load_file(filename:, parse_json: false)
    f = File.read(filename)
    return parse_json ? JSON.parse(f) : f
  end

  #
  # ファイルに文字列を書き込む
  #
  def self.write_to_file(text:, filename:, append_mode: false)
    mode = append_mode ? 'a' : 'w'
    File.open(filename, mode) do |f|
      f.puts text
    end
  end
end
