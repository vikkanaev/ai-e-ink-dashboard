require 'json'
require 'fileutils'

class DataStore
  def initialize(store_path: 'tmp/data_store.json', clock: Time)
    @store_path = store_path
    @clock = clock
    @cache = {}
    load_from_disk
  end

  def write(key, value, ttl:)
    normalized = JSON.parse(JSON.generate(value))
    @cache[key.to_s] = {
      'value' => normalized,
      'expires_at' => @clock.now.to_f + ttl
    }
    persist_to_disk
    value
  end

  def read(key)
    entry = @cache[key.to_s]
    return nil if entry.nil?

    if expired?(entry)
      @cache.delete(key.to_s)
      persist_to_disk
      return nil
    end

    entry['value']
  end

  def stale?(key)
    read(key).nil?
  end

  def fetch(key, ttl:, &block)
    value = read(key)
    return value unless value.nil?

    value = block.call
    write(key, value, ttl: ttl)
    value
  end

  private

  def expired?(entry)
    @clock.now.to_f >= entry['expires_at']
  end

  def load_from_disk
    return unless File.exist?(@store_path)

    raw = File.read(@store_path)
    @cache = JSON.parse(raw)
  rescue JSON::ParserError
    @cache = {}
  end

  def persist_to_disk
    FileUtils.mkdir_p(File.dirname(@store_path))
    File.write(@store_path, JSON.generate(@cache))
  end
end
