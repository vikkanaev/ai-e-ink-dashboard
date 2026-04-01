require 'rack/test'
require 'api_routes'
require 'data_store'
require 'json'

RSpec.describe ApiRoutes do
  include Rack::Test::Methods

  let(:store_path) { "tmp/test_api_store_#{Process.pid}.json" }
  let(:data_store) { DataStore.new(store_path: store_path) }

  def app
    ApiRoutes.new(data_store: data_store)
  end

  after { FileUtils.rm_f(store_path) }

  describe 'GET /data' do
    context 'when data store is empty' do
      it 'returns 503' do
        get '/data'
        expect(last_response.status).to eq(503)
      end

      it 'returns JSON error' do
        get '/data'
        body = JSON.parse(last_response.body)
        expect(body['error']).to be_a(String)
      end
    end

    context 'when data store has data' do
      before do
        data_store.write(:wakatime, { 'total_seconds' => 100 }, ttl: 600)
        data_store.write(:calendar, [], ttl: 600)
        data_store.write(:tokens, { 'used' => 1_000_000 }, ttl: 600)
      end

      it 'returns 200' do
        get '/data'
        expect(last_response.status).to eq(200)
      end

      it 'has application/json content type' do
        get '/data'
        expect(last_response.content_type).to include('application/json')
      end

      it 'returns wakatime data' do
        get '/data'
        body = JSON.parse(last_response.body)
        expect(body['wakatime']['total_seconds']).to eq(100)
      end

      it 'returns calendar data' do
        get '/data'
        body = JSON.parse(last_response.body)
        expect(body['calendar']).to eq([])
      end

      it 'returns updated_at timestamp' do
        get '/data'
        body = JSON.parse(last_response.body)
        expect(body['updated_at']).to be_a(String)
      end
    end
  end

  describe 'GET /status' do
    it 'returns 200' do
      get '/status'
      expect(last_response.status).to eq(200)
    end

    it 'returns status ok' do
      get '/status'
      body = JSON.parse(last_response.body)
      expect(body['status']).to eq('ok')
    end

    it 'returns uptime' do
      get '/status'
      body = JSON.parse(last_response.body)
      expect(body['uptime']).to be_a(Integer)
    end
  end
end
