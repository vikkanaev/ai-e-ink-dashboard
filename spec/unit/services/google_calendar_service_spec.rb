require 'date'
require 'google_calendar_service'

RSpec.describe GoogleCalendarService do
  subject(:service) { described_class.new(access_token: access_token, date: date) }

  let(:access_token) { 'test_token' }
  let(:date)         { Date.new(2026, 4, 1) }
  let(:fixture)      { File.read('spec/support/fixtures/calendar_response.json') }

  describe '#call' do
    context 'with a valid response' do
      before do
        stub_request(:get, /googleapis\.com/)
          .to_return(status: 200, body: fixture, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns an array of events' do
        expect(service.call).to be_an(Array)
        expect(service.call.size).to eq(3)
      end

      it 'includes event fields' do
        event = service.call.first
        expect(event['summary']).to eq('Standup')
        expect(event['start']).to eq('2026-04-01T10:00:00+03:00')
      end

      it 'handles nil location' do
        event = service.call[1]
        expect(event['location']).to be_nil
      end
    end

    context 'with no events' do
      before do
        stub_request(:get, /googleapis\.com/)
          .to_return(status: 200, body: '{"items":[]}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns empty array' do
        expect(service.call).to eq([])
      end
    end

    context 'with HTTP 403' do
      before do
        stub_request(:get, /googleapis\.com/).to_return(status: 403, body: 'Forbidden')
      end

      it 'raises ServiceError' do
        expect { service.call }.to raise_error(ExternalApiBase::ServiceError)
      end
    end
  end
end
