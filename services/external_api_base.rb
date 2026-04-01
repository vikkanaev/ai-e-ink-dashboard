require 'faraday'
require 'faraday/retry'

class ExternalApiBase
  DEFAULT_TIMEOUT = 10
  DEFAULT_RETRIES = 3
  RETRY_DELAY = 1

  class ServiceError < StandardError; end
  class TimeoutError < ServiceError; end
  class NetworkError < ServiceError; end
  class ParseError < ServiceError; end

  def initialize(timeout: DEFAULT_TIMEOUT, retries: DEFAULT_RETRIES, connection: nil)
    @timeout = timeout
    @retries = retries
    @connection = connection || build_connection
  end

  def call
    response = @connection.get(url)
    handle_error_status(response)
    parse_response(response)
  rescue Faraday::TimeoutError => e
    raise TimeoutError, "Request timed out: #{e.message}"
  rescue Faraday::ConnectionFailed => e
    raise NetworkError, "Connection failed: #{e.message}"
  rescue ParseError, ServiceError
    raise
  rescue StandardError => e
    raise NetworkError, "Unexpected error: #{e.message}"
  end

  private

  def url
    raise NotImplementedError, "#{self.class}#url is not implemented"
  end

  def parse_response(_response)
    raise NotImplementedError, "#{self.class}#parse_response is not implemented"
  end

  def handle_error_status(response)
    return if response.success?

    if response.status >= 400 && response.status < 500
      raise ServiceError, "Client error #{response.status}: #{response.body}"
    elsif response.status >= 500
      raise ServiceError, "Server error #{response.status}: #{response.body}"
    end
  end

  def build_connection
    Faraday.new do |f|
      f.request :json
      f.response :json, content_type: /\bjson$/
      f.request :retry, retry_options
      f.options.timeout = @timeout
      f.options.open_timeout = @timeout
    end
  end

  def retry_options
    {
      max: @retries,
      interval: RETRY_DELAY,
      interval_randomness: 0.5,
      backoff_factor: 2,
      exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed, 'Net::ReadTimeout'],
      retry_statuses: [500, 502, 503, 504]
    }
  end
end
