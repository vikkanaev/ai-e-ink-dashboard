require 'wakatime_widget'

RSpec.describe WakatimeWidget do
  subject(:widget) { described_class.new(data: data) }

  let(:data) do
    {
      'total_seconds' => 15_780,
      'date' => '2026-04-01',
      'languages' => [
        { 'name' => 'Ruby',       'total_seconds' => 7800 },
        { 'name' => 'JavaScript', 'total_seconds' => 3900 },
        { 'name' => 'Python',     'total_seconds' => 2700 },
        { 'name' => 'YAML',       'total_seconds' => 1080 }
      ]
    }
  end

  describe '#to_h' do
    it 'formats total duration' do
      expect(widget.to_h['total_hours']).to eq('4ч 23м')
    end

    it 'returns top language' do
      expect(widget.to_h['top_language']).to eq('Ruby')
    end

    it 'calculates bar_percentage against daily goal' do
      # 15780 / 21600 = 73%
      expect(widget.to_h['bar_percentage']).to eq(73)
    end

    it 'returns date' do
      expect(widget.to_h['date']).to eq('2026-04-01')
    end

    it 'caps bar_percentage at 100' do
      over_data = data.merge('total_seconds' => 100_000)
      expect(described_class.new(data: over_data).to_h['bar_percentage']).to eq(100)
    end

    it 'includes up to 4 languages' do
      expect(widget.to_h['languages'].size).to eq(4)
    end

    it 'formats language duration' do
      lang = widget.to_h['languages'].first
      expect(lang['duration']).to eq('2ч 10м')
    end

    it 'sets top language bar to 100%' do
      lang = widget.to_h['languages'].first
      expect(lang['bar_percentage']).to eq(100)
    end

    it 'handles missing languages' do
      empty_data = data.merge('languages' => [])
      result = described_class.new(data: empty_data).to_h
      expect(result['languages']).to eq([])
      expect(result['top_language']).to be_nil
    end

    it 'formats sub-hour duration' do
      short_data = data.merge('total_seconds' => 1800)
      expect(described_class.new(data: short_data).to_h['total_hours']).to eq('30м')
    end
  end
end
