class WakatimeWidget
  DAILY_GOAL_SECONDS = 6 * 3600

  def initialize(data:)
    @data = data
  end

  def to_h
    total = @data['total_seconds'].to_i
    languages = @data['languages'] || []
    {
      'total_hours' => format_duration(total),
      'total_seconds' => total,
      'top_language' => top_language(languages),
      'bar_percentage' => percentage(total, DAILY_GOAL_SECONDS),
      'date' => @data['date'],
      'languages' => format_languages(languages)
    }
  end

  private

  def top_language(languages)
    languages.max_by { |l| l['total_seconds'].to_i }&.dig('name')
  end

  def format_languages(languages)
    max_seconds = languages.first&.dig('total_seconds').to_i
    languages.first(4).map do |lang|
      secs = lang['total_seconds'].to_i
      { 'name' => lang['name'], 'duration' => format_duration(secs), 'bar_percentage' => percentage(secs, max_seconds) }
    end
  end

  def format_duration(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    if hours.positive?
      "#{hours}ч #{minutes}м"
    else
      "#{minutes}м"
    end
  end

  def percentage(value, total)
    return 0 if total.zero?

    [(value * 100 / total).round, 100].min
  end
end
