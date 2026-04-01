require 'rack/test'
require 'dashboard_routes'
require 'data_store'
require 'image_renderer'

RSpec.describe DashboardRoutes do
  include Rack::Test::Methods

  let(:store_path) { "tmp/test_routes_store_#{Process.pid}.json" }
  let(:data_store) { DataStore.new(store_path: store_path) }
  let(:fake_png)   { ChunkyPNG::Image.new(800, 480, ChunkyPNG::Color::WHITE).to_blob }
  let(:mock_renderer) { instance_double(ImageRenderer, render: fake_png) }

  def app
    DashboardRoutes.new(data_store: data_store, image_renderer: mock_renderer)
  end

  after { FileUtils.rm_f(store_path) }

  describe 'GET /image' do
    context 'when data store has data' do
      before do
        data_store.write(:wakatime, { 'total_seconds' => 100, 'languages' => [], 'date' => '2026-04-01' }, ttl: 600)
      end

      it 'returns 200' do
        get '/image'
        expect(last_response.status).to eq(200)
      end

      it 'has image/png content type' do
        get '/image'
        expect(last_response.content_type).to eq('image/png')
      end

      it 'calls image renderer' do
        get '/image'
        expect(mock_renderer).to have_received(:render)
      end
    end

    context 'when data store is empty' do
      it 'returns 200 with nil widget data passed to renderer' do
        get '/image'
        expect(last_response.status).to eq(200)
        expect(mock_renderer).to have_received(:render).with(
          hash_including(wakatime: nil, calendar: nil, tokens: nil)
        )
      end
    end
  end

  describe 'GET /preview' do
    before do
      data_store.write(:calendar, [], ttl: 600)
    end

    it 'returns 200' do
      get '/preview'
      expect(last_response.status).to eq(200)
    end

    it 'has text/html content type' do
      get '/preview'
      expect(last_response.content_type).to include('text/html')
    end

    it 'renders HTML with dashboard structure' do
      get '/preview'
      expect(last_response.body).to include('<!DOCTYPE html>')
      expect(last_response.body).to include('WakaTime')
    end
  end
end
