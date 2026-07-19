class SendInvoiceRemindersAction < MoActions::Base
  display_name "Send Invoice Reminders"
  description "Emails a reminder to every customer with an overdue invoice."
  category :billing

  argument :days_overdue, type: :integer, required: true, description: "Only remind for invoices at least this many days overdue"
  argument :dry_run, type: :boolean, description: "Log what would be sent without emailing"

  def perform
    Rails.logger.info(
      "Pretending to send invoice reminders (days_overdue=#{days_overdue.inspect}, dry_run=#{dry_run.inspect})."
    )
  end
end
