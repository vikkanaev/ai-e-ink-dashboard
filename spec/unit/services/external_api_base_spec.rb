require 'external_api_base'

RSpec.describe ExternalApiBase do
  subject(:service) { concrete_class.new(connection: connection) }

  let(:concrete_class) do
    Class.new(described_class) do
      def url
        'https://example.com/api'
      end

      def parse_response(response)
        response.body
      end
    end
  end

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:connection) do
    Faraday.new do |f|
      f.request :json
      f.response :json, content_type: /\bjson$/
      f.adapter :test, stubs
    end
  end

  describe '#call' do
    context 'when request succeeds' do
      before do
        stubs.get('https://example.com/api') { [200, { 'Content-Type' => 'application/json' }, '{"key":"value"}'] }
      end

      it 'returns parsed response' do
        expect(service.call).to eq({ 'key' => 'value' })
      end
    end

    context 'when HTTP 4xx' do
      before do
        stubs.get('https://example.com/api') { [404, {}, 'Not Found'] }
      end

      it 'raises ServiceError without retry' do
        expect { service.call }.to raise_error(ExternalApiBase::ServiceError, /404/)
      end
    end

    context 'when HTTP 5xx' do
      before do
        stubs.get('https://example.com/api') { [500, {}, 'Server Error'] }
      end

      it 'raises ServiceError' do
        expect { service.call }.to raise_error(ExternalApiBase::ServiceError, /500/)
      end
    end

    context 'when parse_response raises ParseError' do
      subject(:service) { failing_class.new(connection: connection) }

      let(:failing_class) do
        Class.new(described_class) do
          def url
            'https://example.com/api'
          end

          def parse_response(_response)
            raise ExternalApiBase::ParseError, 'bad format'
          end
        end
      end

      before do
        stubs.get('https://example.com/api') { [200, { 'Content-Type' => 'application/json' }, '{}'] }
      end

      it 'raises ParseError' do
        expect { service.call }.to raise_error(ExternalApiBase::ParseError, 'bad format')
      end
    end

    context 'when url is not implemented' do
      subject(:service) { described_class.new(connection: connection) }

      it 'raises NotImplementedError' do
        expect { service.call }.to raise_error(NotImplementedError)
      end
    end

    context 'when parse_response is not implemented' do
      subject(:service) { no_parse_class.new(connection: connection) }

      let(:no_parse_class) do
        Class.new(described_class) do
          def url
            'https://example.com/api'
          end
        end
      end

      before do
        stubs.get('https://example.com/api') { [200, { 'Content-Type' => 'application/json' }, '{}'] }
      end

      it 'raises NotImplementedError' do
        expect { service.call }.to raise_error(NotImplementedError)
      end
    end
  end

  describe 'exception hierarchy' do
    it 'TimeoutError is a ServiceError' do
      expect(ExternalApiBase::TimeoutError.ancestors).to include(ExternalApiBase::ServiceError)
    end

    it 'NetworkError is a ServiceError' do
      expect(ExternalApiBase::NetworkError.ancestors).to include(ExternalApiBase::ServiceError)
    end

    it 'ParseError is a ServiceError' do
      expect(ExternalApiBase::ParseError.ancestors).to include(ExternalApiBase::ServiceError)
    end

    it 'ServiceError is a StandardError' do
      expect(ExternalApiBase::ServiceError.ancestors).to include(StandardError)
    end
  end
end
