require_relative 'external_api_base'

class WakatimeService < ExternalApiBase
  BASE_URL = 'https://wakatime.com/api/v1'.freeze

  def initialize(api_key:, date: Date.today, **)
    super(**)
    @api_key = api_key
    @date = date.to_s
  end

  private

  def url
    "#{BASE_URL}/users/current/summaries?start=#{@date}&end=#{@date}&api_key=#{@api_key}"
  end

  def parse_response(response)
    data = response.body
    entry = data.dig('data', 0)
    raise ExternalApiBase::ParseError, 'Missing data in Wakatime response' if entry.nil?

    grand_total = entry['grand_total'] || {}
    languages = (entry['languages'] || []).map do |lang|
      { 'name' => lang['name'], 'total_seconds' => lang['total_seconds'].to_i }
    end

    {
      'total_seconds' => grand_total['total_seconds'].to_i,
      'languages' => languages,
      'date' => entry.dig('range', 'date') || @date
    }
  end
end
