#
# Zaimの取得結果を元にLineで送信するメッセージを構築する
#
class MessageBuilder
  #
  # 支払い一覧を表す配列で初期化する
  #
  def initialize(moneys)
    @moneys = moneys
  end

  #
  # 全ての支払い情報のメッセージを構築する
  #
  def build_all(header: nil, footer: nil, break_lines_num: 2)
    @moneys.empty? and return "#{title}\n該当の支払いはありません"

    break_line = "\n" * break_lines_num
    body = @moneys.map(&method(:build)).join(break_line)
    [header, body, footer].compact.join(break_line)
  end

  #
  # ヘルプメッセージを生成
  #
  def self.help
    [
      "次のように聞いてね！",
      "",
      "「今日の公費一覧」",
      "「昨日の公費一覧」",
      "「一昨日の公費一覧」",
      "「4日前の公費一覧」",
      "「13日の公費一覧」",
      "「6月3日の公費一覧」",
    ].join("\n")
  end

  private

    #
    # 支払い情報のメッセージを構築する
    #
    def build(money)
      [
        "[場所] #{get_place(money)}",
        "[内容] #{get_comment(money)}",
        "[金額] #{money['amount']} 円",
      ].join("\n")
    end

    def get_place(money)
      money['place'].empty? and return '未入力'
      money['place']
    end

    def get_comment(money)
      comment = money['comment'].gsub(/公費/, '').gsub(/私費/, '').chomp
      comment.empty? ? '未入力' : comment
    end
end
