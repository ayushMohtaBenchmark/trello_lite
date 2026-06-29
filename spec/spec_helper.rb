# SimpleCov must start before any application code is loaded.
require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter %r{^/config/}
  add_filter %r{^/spec/}
  add_filter %r{^/app/channels/}
  add_filter "app/jobs/application_job.rb"
  add_filter "app/mailers/application_mailer.rb"

  add_group "Models",      "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Serializers", "app/serializers"
  add_group "Services",    "app/services"
  add_group "Policies",    "app/policies"

  # Enforce the capstone coverage bar when COVERAGE=true (CI default).
  minimum_coverage(90) if ENV["COVERAGE"] == "true"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
