require 'sinatra/base'
require_relative '../widgets/wakatime_widget'
require_relative '../widgets/calendar_widget'
require_relative '../widgets/tokens_widget'
require_relative '../services/image_renderer'

class DashboardRoutes < Sinatra::Base
  set :views, File.expand_path('../views', __dir__)
  set :host_authorization, { permitted_hosts: [] }

  def initialize(data_store:, image_renderer: nil, **)
    super(**)
    @data_store = data_store
    @image_renderer = image_renderer || ImageRenderer.new
  end

  get '/image' do
    data = build_dashboard_data
    png = @image_renderer.render(data)
    content_type 'image/png'
    png
  end

  get '/preview' do
    data = build_dashboard_data
    ctx = ImageRenderer::TemplateContext.new(data)
    erb :dashboard, locals: {}, layout: false, scope: ctx
  end

  private

  def build_dashboard_data
    wakatime_raw = @data_store.read(:wakatime)
    calendar_raw = @data_store.read(:calendar)
    tokens_raw   = @data_store.read(:tokens)

    wakatime = wakatime_raw ? WakatimeWidget.new(data: wakatime_raw).to_h : nil
    calendar = calendar_raw ? CalendarWidget.new(events: calendar_raw).to_h : nil
    tokens   = tokens_raw   ? TokensWidget.new(data: tokens_raw).to_h : nil

    {
      wakatime: wakatime,
      calendar: calendar,
      tokens: tokens,
      date_str: Time.now.strftime('%-d %B %Y'),
      time_str: Time.now.strftime('%H:%M'),
      updated_at: Time.now.strftime('%H:%M')
    }
  end
end
