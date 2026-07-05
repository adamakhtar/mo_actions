Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.action_controller.allow_forgery_protection = false
  config.active_record.migration_error = false
  config.active_record.maintain_test_schema = false
  config.active_support.deprecation = :stderr
end
