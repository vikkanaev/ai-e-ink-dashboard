require 'rufus-scheduler'

class Scheduler
  TTLS = {
    wakatime: 600,
    calendar: 300,
    tokens: 3600
  }.freeze

  def initialize(data_store:, services:, interval: 600)
    @data_store = data_store
    @services = services
    @interval = interval
    @rufus = nil
  end

  def start
    poll_all
    @rufus = Rufus::Scheduler.new
    @rufus.every("#{@interval}s") { poll_all }
    self
  end

  def stop
    @rufus&.stop
    @rufus = nil
  end

  private

  def poll_all
    @services.each do |key, service|
      result = service.call
      ttl = TTLS.fetch(key, @interval)
      @data_store.write(key, result, ttl: ttl)
    rescue StandardError => e
      warn "[Scheduler] Failed to fetch #{key}: #{e.class}: #{e.message}"
    end
  end
end
