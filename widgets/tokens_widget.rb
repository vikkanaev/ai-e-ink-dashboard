require 'time'

class TokensWidget
  WARNING_THRESHOLD = 90

  def initialize(data:)
    @data = data
  end

  def to_h
    used  = @data['used'].to_i
    limit = @data['limit'].to_i
    pct   = limit.positive? ? [(used * 100 / limit).round, 100].min : 0

    {
      'used' => format_tokens(used),
      'limit' => format_tokens(limit),
      'used_raw' => used,
      'limit_raw' => limit,
      'percentage' => pct,
      'warning' => pct >= WARNING_THRESHOLD,
      'reset_at' => format_reset(@data['reset_at'])
    }
  end

  private

  def format_tokens(count)
    millions = count.to_f / 1_000_000
    "#{millions.round(1)}M"
  end

  def format_reset(raw)
    return nil if raw.nil?

    days = ((Time.parse(raw) - Time.now) / 86_400).ceil
    days.positive? ? "через #{days} дн" : 'сегодня'
  rescue ArgumentError
    nil
  end
end
