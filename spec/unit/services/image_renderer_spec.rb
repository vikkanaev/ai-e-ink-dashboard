require 'image_renderer'

RSpec.describe ImageRenderer do
  subject(:renderer) { described_class.new(browser: mock_browser) }

  let(:dashboard_data) do
    {
      wakatime: {
        'total_hours' => '4ч 23м',
        'bar_percentage' => 73,
        'languages' => [
          { 'name' => 'Ruby', 'duration' => '2ч 10м', 'bar_percentage' => 100 }
        ]
      },
      calendar: {
        'today' => 'Вторник, 1 апреля',
        'events' => [
          { 'time' => '10:00', 'title' => 'Standup', 'location' => nil, 'current' => false }
        ]
      },
      tokens: {
        'used' => '8.2M', 'limit' => '20.0M',
        'percentage' => 41, 'warning' => false,
        'reset_at' => 'через 3 дн'
      },
      date_str: 'Вторник, 1 апреля 2026',
      time_str: '14:35',
      updated_at: '14:30'
    }
  end

  let(:fake_png) { ChunkyPNG::Image.new(800, 480, ChunkyPNG::Color::WHITE).to_blob }
  let(:mock_browser) { double('browser') }
  let(:mock_page)    { double('page') }

  before do
    allow(mock_browser).to receive(:create_page).and_return(mock_page)
    allow(mock_browser).to receive(:quit)
    allow(mock_page).to receive(:content=)
    allow(mock_page).to receive(:resize)
    allow(mock_page).to receive(:screenshot).with(hash_including(full_page: false)).and_return(fake_png)
  end

  describe '#render' do
    it 'returns a PNG binary string' do
      result = renderer.render(dashboard_data)
      expect(result.b).to start_with("\x89PNG".b)
    end

    it 'calls page screenshot' do
      renderer.render(dashboard_data)
      expect(mock_page).to have_received(:screenshot)
    end

    it 'sets page content to HTML' do
      renderer.render(dashboard_data)
      expect(mock_page).to have_received(:content=).with(a_string_including('<!DOCTYPE html>'))
    end

    it 'sets viewport size' do
      renderer.render(dashboard_data)
      expect(mock_page).to have_received(:resize).with(width: 800, height: 480)
    end
  end

  describe 'PNG converter' do
    it 'produces 1-bit PNG with only black and white pixels' do
      result = renderer.render(dashboard_data)
      image = ChunkyPNG::Image.from_blob(result)
      non_bw = 0
      image.height.times do |y|
        image.width.times do |x|
          px = image[x, y]
          non_bw += 1 unless [ChunkyPNG::Color::WHITE, ChunkyPNG::Color::BLACK].include?(px)
        end
      end
      expect(non_bw).to eq(0)
    end
  end

  describe 'custom png_converter' do
    it 'calls the injected converter with screenshot bytes' do
      custom_converter = double('converter')
      allow(custom_converter).to receive(:call).and_return(fake_png)
      renderer = described_class.new(browser: mock_browser, png_converter: custom_converter)
      renderer.render(dashboard_data)
      expect(custom_converter).to have_received(:call).with(fake_png)
    end
  end
end
