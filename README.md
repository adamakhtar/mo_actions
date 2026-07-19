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

Visiting the dashboard lists all registered actions grouped by category, each with a Run button that invokes the action's `perform` method synchronously.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "mo_actions"
```

And then execute:

```bash
$ bundle
```

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
