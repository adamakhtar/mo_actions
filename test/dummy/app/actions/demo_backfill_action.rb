# Slow on purpose so a dashboard reload can observe progress in development.
class DemoBackfillAction < MoActions::Base
  display_name "Demo Backfill"
  description "Sleeps between steps so you can refresh the execution page and watch progress."
  category :testing

  argument :steps, type: :integer, required: true, description: "How many units of work to simulate"

  def perform(ctx)
    total = [ steps, 1 ].max
    ctx.total = total
    total.times do |i|
      sleep 1 unless Rails.env.test?
      ctx.progress(i + 1)
    end
  end
end
