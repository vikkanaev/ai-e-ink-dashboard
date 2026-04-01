require 'erb'
require 'chunky_png'

class ImageRenderer
  WIDTH     = 800
  HEIGHT    = 480
  THRESHOLD = 128
  VIEWS_DIR = File.expand_path('../views', __dir__)

  def initialize(browser: nil, png_converter: nil)
    @browser = browser
    @png_converter = png_converter || method(:default_convert)
  end

  def render(dashboard_data)
    html = render_html(dashboard_data)
    png_bytes = screenshot_html(html)
    @png_converter.call(png_bytes)
  end

  private

  def render_html(data)
    template_path = File.join(VIEWS_DIR, 'dashboard.erb')
    template = ERB.new(File.read(template_path))
    ctx = TemplateContext.new(data)
    template.result(ctx.get_binding)
  end

  def screenshot_html(html)
    browser = @browser || build_browser
    page = browser.create_page
    page.content = html
    page.resize(width: WIDTH, height: HEIGHT)
    screenshot = page.screenshot(full_page: false, encoding: :binary)
    browser.quit unless @browser
    screenshot
  end

  def default_convert(png_bytes)
    image  = ChunkyPNG::Image.from_blob(png_bytes)
    result = ChunkyPNG::Image.new(WIDTH, HEIGHT, ChunkyPNG::Color::WHITE)
    HEIGHT.times { |y| WIDTH.times { |x| result[x, y] = quantize_pixel(image[x, y]) } }
    result.to_blob
  end

  def quantize_pixel(pixel)
    r = ChunkyPNG::Color.r(pixel)
    g = ChunkyPNG::Color.g(pixel)
    b = ChunkyPNG::Color.b(pixel)
    luminance = ((0.299 * r) + (0.587 * g) + (0.114 * b)).round
    luminance < THRESHOLD ? ChunkyPNG::Color::BLACK : ChunkyPNG::Color::WHITE
  end

  def build_browser
    require 'ferrum'
    Ferrum::Browser.new(headless: true, window_size: [WIDTH, HEIGHT])
  end

  # Provides a clean binding for ERB template rendering
  class TemplateContext
    def initialize(data)
      @data = data
    end

    def wakatime   = @data[:wakatime]
    def calendar   = @data[:calendar]
    def tokens     = @data[:tokens]
    def date_str   = @data[:date_str]   || Time.now.strftime('%-d %B %Y')
    def time_str   = @data[:time_str]   || Time.now.strftime('%H:%M')
    def updated_at = @data[:updated_at] || Time.now.strftime('%H:%M')

    def get_binding # rubocop:disable Naming/AccessorMethodName
      binding
    end
  end
end
