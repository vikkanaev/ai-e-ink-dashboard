require 'playwright'

module PlaywrightHelper
  def with_playwright_page
    Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
      browser = playwright.chromium.launch(headless: true)
      page = browser.new_page
      yield page
    ensure
      browser&.close
    end
  end
end
