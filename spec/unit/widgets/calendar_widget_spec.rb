require 'calendar_widget'

RSpec.describe CalendarWidget do
  subject(:widget) { described_class.new(events: events) }

  let(:events) do
    [
      { 'summary' => 'Standup',       'start' => '2026-04-01T10:00:00+03:00', 'location' => 'Google Meet' },
      { 'summary' => '1:1 с Артёмом', 'start' => '2026-04-01T14:00:00+03:00', 'location' => nil },
      { 'summary' => 'Deploy prod',   'start' => '2026-04-01T17:00:00+03:00', 'location' => nil }
    ]
  end

  describe '#to_h' do
    it 'returns today formatted' do
      expect(widget.to_h['today']).to be_a(String)
      expect(widget.to_h['today']).not_to be_empty
    end

    it 'returns events array' do
      expect(widget.to_h['events'].size).to eq(3)
    end

    it 'formats event time as HH:MM' do
      expect(widget.to_h['events'].first['time']).to eq('10:00')
    end

    it 'includes event title' do
      expect(widget.to_h['events'].first['title']).to eq('Standup')
    end

    it 'includes event location' do
      expect(widget.to_h['events'].first['location']).to eq('Google Meet')
    end

    it 'handles nil location' do
      expect(widget.to_h['events'][1]['location']).to be_nil
    end

    it 'limits to 6 events' do
      many_events = Array.new(10) do |i|
        { 'summary' => "Event #{i}", 'start' => '2026-04-01T09:00:00+03:00', 'location' => nil }
      end
      result = described_class.new(events: many_events).to_h
      expect(result['events'].size).to eq(6)
    end

    it 'handles empty events' do
      result = described_class.new(events: []).to_h
      expect(result['events']).to eq([])
    end

    it 'handles nil events' do
      result = described_class.new(events: nil).to_h
      expect(result['events']).to eq([])
    end
  end
end
