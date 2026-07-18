class SendInvoiceRemindersAction < MoActions::Base
  display_name "Send Invoice Reminders"
  description "Emails a reminder to every customer with an overdue invoice."
  category :billing

  def perform
    Rails.logger.info "Pretending to send invoice reminders."
  end
end
