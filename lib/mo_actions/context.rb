module MoActions
  # Thin handle passed into +perform+ for progress reporting.
  #
  #   def perform(ctx)
  #     ctx.total = records.count
  #     records.each_with_index { |r, i| work(r); ctx.progress(i + 1) }
  #   end
  class Context
    attr_reader :execution

    def initialize(execution)
      @execution = execution
    end

    def total=(value)
      execution.update!(progress_total: Integer(value))
    end

    def progress(current)
      current = Integer(current)
      current = 0 if current.negative?

      total = execution.progress_total
      current = total if total && current > total

      execution.update!(progress_current: current)
    end
  end
end
