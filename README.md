# Mo Actions

A Rails engine for defining, running, and observing operational actions from an internal dashboard.

## Usage

Define actions in your app under `app/actions`:

```ruby
class SendInvoiceRemindersAction < MoActions::Base
  display_name "Send Invoice Reminders"
  description "Emails a reminder to every customer with an overdue invoice."
  category :billing

  def perform
    # do the work
  end
end
```

Mount the dashboard in `config/routes.rb`:

```ruby
mount MoActions::Engine => "/mo_actions"
```

Install the initializer, then wire host authentication:

```bash
$ bin/rails g mo_actions:install
```

```ruby
# config/initializers/mo_actions.rb
MoActions.configure do |config|
  config.authenticate_with = ->(controller) do
    controller.redirect_to "/login" unless controller.session[:user_id]
  end

  config.current_performer = ->(controller) do
    User.find_by(id: controller.session[:user_id])
  end
end
```

Without `authenticate_with`, the dashboard rejects requests with 403. Visiting the dashboard lists registered actions grouped by category; Run invokes `perform` synchronously.

## Development

Run the test suite:

```bash
$ bin/rails test
```

Run the dummy app:

```bash
$ cd test/dummy && bundle exec rails s
```

See `docs/` for product direction and the working process.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
