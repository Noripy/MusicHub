require "capybara/rspec"

Capybara.default_driver = :rack_test
Capybara.app_host = "http://example.test"
Capybara.server = :puma, { Silent: true }
