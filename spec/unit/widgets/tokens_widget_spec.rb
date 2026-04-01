require 'tokens_widget'

RSpec.describe TokensWidget do
  subject(:widget) { described_class.new(data: data) }

  let(:data) do
    {
      'used' => 8_200_000,
      'limit' => 20_000_000,
      'reset_at' => (Time.now + (3 * 86_400)).iso8601
    }
  end

  describe '#to_h' do
    it 'formats used tokens' do
      expect(widget.to_h['used']).to eq('8.2M')
    end

    it 'formats limit' do
      expect(widget.to_h['limit']).to eq('20.0M')
    end

    it 'calculates percentage' do
      expect(widget.to_h['percentage']).to eq(41)
    end

    it 'caps percentage at 100' do
      over_data = data.merge('used' => 30_000_000)
      expect(described_class.new(data: over_data).to_h['percentage']).to eq(100)
    end

    it 'is not in warning state below 90%' do
      expect(widget.to_h['warning']).to be false
    end

    it 'is in warning state at 90%' do
      warn_data = data.merge('used' => 18_000_000)
      expect(described_class.new(data: warn_data).to_h['warning']).to be true
    end

    it 'returns reset_at message' do
      expect(widget.to_h['reset_at']).to match(/через \d+ дн/)
    end

    it 'returns nil for nil reset_at' do
      no_reset = data.merge('reset_at' => nil)
      expect(described_class.new(data: no_reset).to_h['reset_at']).to be_nil
    end

    it 'handles zero limit' do
      zero_data = data.merge('limit' => 0)
      result = described_class.new(data: zero_data).to_h
      expect(result['percentage']).to eq(0)
    end
  end
end
