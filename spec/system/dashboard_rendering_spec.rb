require 'puma'
require 'puma/server'
require 'playwright'
require 'net/http'
require 'data_store'
require 'dashboard_routes'
require 'image_renderer'

RSpec.describe 'Dashboard rendering', :system do
  let(:store_path) { "tmp/system_test_store_#{Process.pid}.json" }
  let(:data_store) { DataStore.new(store_path: store_path) }
  let(:port)       { rand(19_200..20_000) }
  let(:base_url)   { "http://127.0.0.1:#{port}" }

  before do
    WebMock.allow_net_connect!(allow: /127\.0\.0\.1/)

    data_store.write(:wakatime, {
                       'total_seconds' => 15_780,
                       'languages' => [{ 'name' => 'Ruby', 'total_seconds' => 7800 }],
                       'date' => '2026-04-01'
                     }, ttl: 600)
    data_store.write(:calendar, [], ttl: 600)
    data_store.write(:tokens,
                     { 'used' => 8_200_000, 'limit' => 20_000_000, 'reset_at' => nil },
                     ttl: 600)

    sinatra_app = DashboardRoutes.new(data_store: data_store)

    @puma = Puma::Server.new(sinatra_app)
    @puma.add_tcp_listener('127.0.0.1', port) # rubocop:disable RSpec/InstanceVariable
    @server_thread = Thread.new { @puma.run.join } # rubocop:disable RSpec/InstanceVariable

    Timeout.timeout(5) do
      loop do
        TCPSocket.new('127.0.0.1', port).close
        break
      rescue Errno::ECONNREFUSED
        retry
      end
    end
  end

  after do
    @puma&.stop(true) # rubocop:disable RSpec/InstanceVariable
    @server_thread&.join(2) # rubocop:disable RSpec/InstanceVariable
    FileUtils.rm_f(store_path)
    WebMock.disable_net_connect!
  end

  it 'renders /dashboard/preview as HTML with correct structure' do
    Playwright.create(playwright_cli_executable_path: 'npx playwright@1.58.2') do |playwright|
      browser = playwright.chromium.launch(headless: true)
      page = browser.new_page
      page.goto("#{base_url}/preview")

      expect(page.content).to include('WakaTime')
      expect(page.content).to include('Токены')
      expect(page.content).to include('Сегодня')
    ensure
      browser&.close
    end
  end

  it 'serves /dashboard/image as image/png' do
    response = Net::HTTP.get_response(URI("#{base_url}/image"))
    expect(response.code).to eq('200')
    expect(response['Content-Type']).to eq('image/png')
    expect(response.body.b).to start_with("\x89PNG".b)
  end
end
