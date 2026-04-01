require 'date'
require 'wakatime_service'

RSpec.describe WakatimeService do
  subject(:service) { described_class.new(api_key: api_key, date: date) }

  let(:api_key) { 'test_key' }
  let(:date)    { Date.new(2026, 4, 1) }
  let(:fixture) { File.read('spec/support/fixtures/wakatime_response.json') }

  describe '#call' do
    context 'with a valid response' do
      before do
        stub_request(:get, /wakatime\.com/)
          .to_return(status: 200, body: fixture, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns total_seconds' do
        expect(service.call['total_seconds']).to eq(15_780)
      end

      it 'returns languages array' do
        languages = service.call['languages']
        expect(languages.first['name']).to eq('Ruby')
        expect(languages.first['total_seconds']).to eq(7800)
      end

      it 'returns date' do
        expect(service.call['date']).to eq('2026-04-01')
      end

      it 'includes api_key in request URL' do
        service.call
        expect(WebMock).to have_requested(:get, /api_key=test_key/)
      end
    end

    context 'with empty data' do
      before do
        stub_request(:get, /wakatime\.com/)
          .to_return(status: 200, body: '{"data":[]}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises ParseError' do
        expect { service.call }.to raise_error(ExternalApiBase::ParseError)
      end
    end

    context 'with HTTP 401' do
      before do
        stub_request(:get, /wakatime\.com/).to_return(status: 401, body: 'Unauthorized')
      end

      it 'raises ServiceError' do
        expect { service.call }.to raise_error(ExternalApiBase::ServiceError)
      end
    end
  end
end
