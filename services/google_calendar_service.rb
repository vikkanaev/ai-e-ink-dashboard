require_relative 'external_api_base'

class GoogleCalendarService < ExternalApiBase
  BASE_URL = 'https://www.googleapis.com/calendar/v3/calendars'.freeze

  def initialize(access_token:, calendar_id: 'primary', date: Date.today, **)
    super(**)
    @access_token = access_token
    @calendar_id = calendar_id
    @date = date
  end

  private

  def url
    time_min = "#{@date}T00:00:00Z"
    time_max = "#{@date}T23:59:59Z"
    encoded_id = URI.encode_www_form_component(@calendar_id)
    "#{BASE_URL}/#{encoded_id}/events?timeMin=#{time_min}&timeMax=#{time_max}" \
      "&singleEvents=true&orderBy=startTime&access_token=#{@access_token}"
  end

  def parse_response(response)
    items = response.body['items'] || []
    items.map do |item|
      start_time = item.dig('start', 'dateTime') || item.dig('start', 'date')
      end_time   = item.dig('end', 'dateTime')   || item.dig('end', 'date')
      {
        'summary' => item['summary'].to_s,
        'start' => start_time,
        'end' => end_time,
        'location' => item['location']
      }
    end
  end
end
