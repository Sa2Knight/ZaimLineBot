require_relative 'src/util'
require_relative 'src/line_client'
require_relative 'src/zaim_client'
require_relative 'src/message_builder'

@zaim = ZaimClient.new
@line = LineClient.new

#
# 特定日の公費記録一覧をLineで通知する
#
def send_public_payments_info(date_info)
  unless date = make_date_by(date_info)
    return @line.reply(text: MessageBuilder.help)
  end
  title  = "#{date} の公費一覧です"
  moneys = @zaim.fetch_public_payments(start_date: date, end_date: date)
  total  = @zaim.get_total_amount(moneys)
  message_builder = MessageBuilder.new(moneys)
  @line.reply(
    text: message_builder.build_all(
      header: "#{date} の公費一覧です",
      footer: "合計 #{total} 円"
    )
  )
end

#
# 特定月の公費残高をLineで通知する
#
def send_public_budget_info(month_info)
  date   = make_month_by(month_info)
  budget = @zaim.fetch_month_public_budget(date)
  @line.reply(text: "#{budget} 円")
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

#
# 月を表す文字列から当該月初日のDateオブジェクトを生成する
#
def make_month_by(str)
  # 今月
  return Date.today if str == '今月'
end

# メッセージを解析して各種メソッドを呼び出す
message = Util.get_event_message
if md = message.match(/(.+)の公費残額/)
  send_public_budget_info(md[1])
elsif message == '私費残額'
  @line.reply(text: '私費残額だっよ')
elsif md = message.match(/(.+)の公費一覧/)
  send_public_payments_info(md[1])
end
