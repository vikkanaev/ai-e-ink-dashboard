require 'time'

class CalendarWidget
  MAX_EVENTS = 6

  def initialize(events:)
    @events = events || []
  end

  def to_h
    {
      'today' => Date.today.strftime('%A, %-d %B'),
      'events' => @events.first(MAX_EVENTS).map { |e| format_event(e) }
    }
  end

  private

  def format_event(event)
    start_raw = event['start']
    time_str = parse_time(start_raw)

    {
      'time' => time_str,
      'title' => event['summary'].to_s,
      'location' => event['location']
    }
  end

  def parse_time(raw)
    return '' if raw.nil?

    Time.parse(raw).strftime('%H:%M')
  rescue ArgumentError
    raw.to_s
  end
end
