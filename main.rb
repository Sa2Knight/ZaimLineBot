require_relative 'src/util'
require_relative 'src/line_client'
require_relative 'src/zaim_client'
require_relative 'src/message_builder'

@zaim = ZaimClient.new
@line = LineClient.new

#
# 本日の公費記録をLineで通知する
#
def send_public_payments_info(date = Date.today)
  title  = "#{date} の公費一覧です"
  moneys = @zaim.fetch_public_payments(date: date)
  message_builder = MessageBuilder.new(moneys)
  @line.reply(text: message_builder.build_all(title: title))
end

#
# 日付を表す文字列からDateオブジェクトを生成する
#
def make_date_by(str)
  # 今日、昨日、一昨日
  return Date.today if str == '今日'
  return Date.today - 1 if str == '昨日'
  return Date.today - 2 if str == '一昨日'

  # N日、N日前
  str.tr!('０-９', '0-9')
  if md = str.match(/^(\d+)日(前?)$/)
    return Date.today - md[1].to_i if md[2] == '前'
    return Date.parse("#{Date.today.month}/#{md[1]}")
  end

  # 他parse可能な文字列あるいはfalse
  str.tr!('年月', '/')
  return Date.parse(str) rescue false
end

# メッセージを解析して各種メソッドを呼び出す
message = Util.get_event_message
if md = message.match(/(.+)の公費一覧/)
  if date = make_date_by(md[1])
    send_public_payments_info(date)
  else
    @line.reply(text: MessageBuilder.help)
  end
end
