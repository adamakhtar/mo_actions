module MoActions
  class PreflightRunner
    Result = Struct.new(:execution, :arguments, :check, keyword_init: true) do
      def ready? = execution.ready?

      def schema_invalid? = !arguments.valid?

      def preflight_failed? = check.present? && !check.passed?
    end

    attr_reader :execution, :raw_arguments, :arguments, :check

    def initialize(execution, raw_arguments: execution.arguments)
      @execution = execution
      @raw_arguments = raw_arguments
    end

    def run
      @arguments = Arguments.build(execution.action_class, raw_arguments)
      save_cast_arguments

      unless arguments.valid?
        clear_stale_preflight_results
        return result
      end

      execution.start_preflight!
      @check = PreflightCheck.new
      run_action_preflight

      if check.passed?
        execution.pass_preflight!(check.to_h)
      else
        execution.fail_preflight!(check.to_h)
      end

      result
    end

    private

    def save_cast_arguments
      return unless arguments.castable?

      execution.update!(arguments: arguments.to_h)
    end

    def clear_stale_preflight_results
      execution.update!(preflight_results: nil) if execution.preflight_results.present?
    end

    def run_action_preflight
      execution.action_class.new.preflight(arguments, check)
    rescue StandardError => error
      check.error("#{error.class}: #{error.message}")
    end

    def result
      Result.new(execution: execution, arguments: arguments, check: check)
    end
  end
end
