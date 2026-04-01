require_relative 'external_api_base'

class ClaudeTokensService < ExternalApiBase
  BASE_URL = 'https://api.anthropic.com/v1'.freeze

  def initialize(api_key:, **)
    @api_key = api_key
    super(**)
  end

  private

  def url
    "#{BASE_URL}/usage"
  end

  def build_connection
    Faraday.new do |f|
      f.headers['x-api-key'] = @api_key
      f.headers['anthropic-version'] = '2023-06-01'
      f.request :json
      f.response :json, content_type: /\bjson$/
      f.request :retry, anthropic_retry_options
      f.options.timeout = @timeout
      f.options.open_timeout = @timeout
    end
  end

  def anthropic_retry_options
    {
      max: @retries,
      interval: RETRY_DELAY,
      interval_randomness: 0.5,
      backoff_factor: 2,
      exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed],
      retry_statuses: [500, 502, 503, 504]
    }
  end

  def parse_response(response)
    body = response.body
    {
      'used' => sum_tokens(body['data'] || [], %w[input_tokens output_tokens]),
      'limit' => sum_tokens([body['limit'] || {}], %w[input_tokens output_tokens]),
      'reset_at' => body['reset_at']
    }
  end

  def sum_tokens(records, keys)
    records.sum { |r| keys.sum { |k| r[k].to_i } }
  end
end
