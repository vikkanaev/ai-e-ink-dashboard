require 'claude_tokens_service'

RSpec.describe ClaudeTokensService do
  subject(:service) { described_class.new(api_key: api_key) }

  let(:api_key) { 'sk-ant-test' }
  let(:fixture) { File.read('spec/support/fixtures/claude_tokens_response.json') }

  describe '#call' do
    context 'with a valid response' do
      before do
        stub_request(:get, /anthropic\.com/)
          .to_return(status: 200, body: fixture, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns used tokens' do
        expect(service.call['used']).to eq(8_200_000)
      end

      it 'returns total limit' do
        expect(service.call['limit']).to eq(20_000_000)
      end

      it 'returns reset_at' do
        expect(service.call['reset_at']).to eq('2026-04-04T00:00:00Z')
      end
    end

    context 'with HTTP 401' do
      before do
        stub_request(:get, /anthropic\.com/).to_return(status: 401, body: 'Unauthorized')
      end

      it 'raises ServiceError' do
        expect { service.call }.to raise_error(ExternalApiBase::ServiceError)
      end
    end

    context 'with empty data' do
      before do
        body = '{"data":[],"limit":{"input_tokens":10000000,"output_tokens":10000000},' \
               '"reset_at":"2026-04-04T00:00:00Z"}'
        stub_request(:get, /anthropic\.com/)
          .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns zero used tokens' do
        expect(service.call['used']).to eq(0)
      end
    end
  end
end
