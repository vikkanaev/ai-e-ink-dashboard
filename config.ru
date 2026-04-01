require 'dotenv/load'
require_relative 'app'

run(Rack::Builder.new do
  map '/dashboard' do
    run DASHBOARD_APP
  end

  map '/api' do
    run API_APP
  end
end)
