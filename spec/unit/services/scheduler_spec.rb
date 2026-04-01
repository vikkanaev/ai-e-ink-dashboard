require 'scheduler'
require 'data_store'

RSpec.describe Scheduler do
  subject(:scheduler) { described_class.new(data_store: data_store, services: services) }

  let(:store_path)  { "tmp/test_scheduler_store_#{Process.pid}.json" }
  let(:data_store)  { DataStore.new(store_path: store_path) }
  let(:wakatime_svc) { double('wakatime', call: { 'total_seconds' => 100 }) }
  let(:calendar_svc) { double('calendar', call: []) }
  let(:services) { { wakatime: wakatime_svc, calendar: calendar_svc } }

  after do
    scheduler.stop
    FileUtils.rm_f(store_path)
  end

  describe '#start' do
    it 'polls all services immediately on start' do
      scheduler.start
      expect(wakatime_svc).to have_received(:call).once
      expect(calendar_svc).to have_received(:call).once
    end

    it 'writes wakatime data to store' do
      scheduler.start
      expect(data_store.read(:wakatime)).to eq({ 'total_seconds' => 100 })
    end

    it 'writes calendar data to store' do
      scheduler.start
      expect(data_store.read(:calendar)).to eq([])
    end

    it 'returns self for chaining' do
      expect(scheduler.start).to be(scheduler)
    end
  end

  describe 'error isolation' do
    let(:failing_service) { double('failing', call: nil) }

    before do
      allow(failing_service).to receive(:call).and_raise(StandardError, 'API down')
    end

    it 'does not raise when one service fails' do
      services[:wakatime] = failing_service
      expect { scheduler.start }.not_to raise_error
    end

    it 'still polls other services when one fails' do
      services[:wakatime] = failing_service
      scheduler.start
      expect(calendar_svc).to have_received(:call).once
    end

    it 'logs the error to stderr' do
      services[:wakatime] = failing_service
      expect { scheduler.start }.to output(/Failed to fetch wakatime/).to_stderr
    end
  end

  describe '#stop' do
    it 'does not raise when called before start' do
      expect { scheduler.stop }.not_to raise_error
    end

    it 'stops the scheduler after start' do
      scheduler.start
      expect { scheduler.stop }.not_to raise_error
    end
  end
end
