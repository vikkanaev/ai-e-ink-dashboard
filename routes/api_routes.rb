require 'sinatra/base'
require 'json'

class ApiRoutes < Sinatra::Base
  set :host_authorization, { permitted_hosts: [] }

  def initialize(data_store:, **)
    super(**)
    @data_store = data_store
  end

  before { content_type :json }

  get '/data' do
    wakatime = @data_store.read(:wakatime)
    calendar = @data_store.read(:calendar)
    tokens   = @data_store.read(:tokens)

    halt 503, JSON.generate({ error: 'No data available yet' }) if wakatime.nil? && calendar.nil? && tokens.nil?

    JSON.generate({
                    wakatime: wakatime,
                    calendar: calendar,
                    tokens: tokens,
                    updated_at: Time.now.iso8601
                  })
  end

  get '/status' do
    JSON.generate({
                    status: 'ok',
                    uptime: Process.clock_gettime(Process::CLOCK_MONOTONIC).to_i
                  })
  end
end
