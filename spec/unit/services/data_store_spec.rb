require 'data_store'

RSpec.describe DataStore do
  subject(:store) { described_class.new(store_path: store_path, clock: frozen_time) }

  let(:store_path) { "tmp/test_data_store_#{Process.pid}.json" }
  let(:frozen_time) { double('clock') }

  before { allow(frozen_time).to receive(:now).and_return(Time.at(1_000_000)) }
  after  { FileUtils.rm_f(store_path) }

  describe '#write and #read' do
    it 'stores and retrieves a value' do
      store.write(:wakatime, { total: 42 }, ttl: 600)
      expect(store.read(:wakatime)).to eq({ 'total' => 42 })
    end

    it 'returns nil for unknown key' do
      expect(store.read(:unknown)).to be_nil
    end

    it 'persists to disk on write' do
      store.write(:foo, 'bar', ttl: 600)
      expect(File.exist?(store_path)).to be true
    end
  end

  describe '#read with TTL' do
    it 'returns value before TTL expires' do
      store.write(:key, 'value', ttl: 600)
      allow(frozen_time).to receive(:now).and_return(Time.at(1_000_599))
      expect(store.read(:key)).to eq('value')
    end

    it 'returns nil after TTL expires' do
      store.write(:key, 'value', ttl: 600)
      allow(frozen_time).to receive(:now).and_return(Time.at(1_000_600))
      expect(store.read(:key)).to be_nil
    end

    it 'deletes expired entry from cache' do
      store.write(:key, 'value', ttl: 600)
      allow(frozen_time).to receive(:now).and_return(Time.at(1_000_600))
      store.read(:key)
      allow(frozen_time).to receive(:now).and_return(Time.at(1_000_000))
      expect(store.read(:key)).to be_nil
    end
  end

  describe '#stale?' do
    it 'returns true when key is absent' do
      expect(store.stale?(:missing)).to be true
    end

    it 'returns false when key is fresh' do
      store.write(:key, 'value', ttl: 600)
      expect(store.stale?(:key)).to be false
    end

    it 'returns true when key has expired' do
      store.write(:key, 'value', ttl: 600)
      allow(frozen_time).to receive(:now).and_return(Time.at(1_000_600))
      expect(store.stale?(:key)).to be true
    end
  end

  describe '#fetch' do
    it 'returns cached value when fresh' do
      store.write(:key, 'cached', ttl: 600)
      called = false
      result = store.fetch(:key, ttl: 600) do
        called = true
        'new'
      end
      expect(result).to eq('cached')
      expect(called).to be false
    end

    it 'calls block and stores result when stale' do
      result = store.fetch(:key, ttl: 600) { 'computed' }
      expect(result).to eq('computed')
      expect(store.read(:key)).to eq('computed')
    end

    it 'returns block result after TTL expires' do
      store.write(:key, 'old', ttl: 600)
      allow(frozen_time).to receive(:now).and_return(Time.at(1_000_600))
      result = store.fetch(:key, ttl: 600) { 'fresh' }
      expect(result).to eq('fresh')
    end
  end

  describe 'persistence across instances' do
    it 'loads data written by previous instance' do
      store.write(:key, 'persisted', ttl: 600)
      new_store = described_class.new(store_path: store_path, clock: frozen_time)
      expect(new_store.read(:key)).to eq('persisted')
    end

    it 'handles corrupt JSON file gracefully' do
      FileUtils.mkdir_p(File.dirname(store_path))
      File.write(store_path, 'NOT_JSON')
      new_store = described_class.new(store_path: store_path, clock: frozen_time)
      expect(new_store.read(:anything)).to be_nil
    end
  end
end
