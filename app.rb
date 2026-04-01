require 'bundler/setup'
require 'dotenv/load'

# Services
require_relative 'services/external_api_base'
require_relative 'services/data_store'
require_relative 'services/wakatime_service'
require_relative 'services/google_calendar_service'
require_relative 'services/claude_tokens_service'
require_relative 'services/image_renderer'
require_relative 'services/scheduler'

# Widgets
require_relative 'widgets/wakatime_widget'
require_relative 'widgets/calendar_widget'
require_relative 'widgets/tokens_widget'

# Routes
require_relative 'routes/dashboard_routes'
require_relative 'routes/api_routes'

DATA_STORE = DataStore.new(store_path: 'tmp/data_store.json')

api_services = {}

api_services[:wakatime] = WakatimeService.new(api_key: ENV['WAKATIME_API_KEY']) if ENV['WAKATIME_API_KEY']

if ENV['GOOGLE_ACCESS_TOKEN']
  api_services[:calendar] = GoogleCalendarService.new(
    access_token: ENV['GOOGLE_ACCESS_TOKEN'],
    calendar_id: ENV.fetch('GOOGLE_CALENDAR_ID', 'primary')
  )
end

api_services[:tokens] = ClaudeTokensService.new(api_key: ENV['ANTHROPIC_API_KEY']) if ENV['ANTHROPIC_API_KEY']

SCHEDULER = Scheduler.new(data_store: DATA_STORE, services: api_services)
SCHEDULER.start unless api_services.empty?

DASHBOARD_APP = DashboardRoutes.new(data_store: DATA_STORE)
API_APP = ApiRoutes.new(data_store: DATA_STORE)

if __FILE__ == $PROGRAM_NAME
  require 'puma'
  require 'puma/server'
  app = Rack::Builder.new do
    map('/dashboard') { run DASHBOARD_APP }
    map('/api') { run API_APP }
  end
  port = ENV.fetch('PORT', 4567).to_i
  server = Puma::Server.new(app)
  server.add_tcp_listener('0.0.0.0', port)
  puts "== Sinatra on http://0.0.0.0:#{port}"
  server.run.join
end
