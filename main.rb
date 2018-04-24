require_relative 'src/util'
require_relative 'src/line_client'
require_relative 'src/zaim_client'
require_relative 'src/message_builder'

@zaim = ZaimClient.new
@line = LineClient.new

#
# 特定日の公費記録一覧をLineで通知する
#
def send_public_payments_info(date_info, type)
  unless date = make_date_by(date_info)
    return @line.reply(text: MessageBuilder.help)
  end
  title  = "#{date} の#{type}一覧です"
  moneys = if type == '公費'
             @zaim.fetch_public_payments(start_date: date, end_date: date)
           else
             @zaim.fetch_private_payments(start_date: date, end_date: date)
           end
  total  = @zaim.get_total_amount(moneys)
  message_builder = MessageBuilder.new(moneys)
  message = message_builder.build_all(
    header: title,
    footer: "合計 #{total} 円"
  )
  @line.reply(text: message)
  Util.write_log(message)
end

#
# 特定月の公費及び私費残額をLineで通知する
#
def send_budget_info(month_info)
  date   = make_month_by(month_info)
  public_budget  = @zaim.fetch_month_public_budget(date)
  private_budget = @zaim.fetch_month_private_budget(date)
  text = [
    "公費: #{public_budget} 円",
    "私費: #{private_budget} 円"
  ].join("\n")
  @line.reply(text: text)
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
if md = message.match(/(.+)の残額/)
  send_budget_info(md[1])
elsif md = message.match(/(.+)の(公費|私費)/)
  send_public_payments_info(md[1], md[2])
end
