module MoActions
  class PreflightCheck
    attr_reader :errors, :infos, :warnings

    def initialize(errors: [], infos: [], warnings: [])
      @errors = Array(errors)
      @infos = Array(infos)
      @warnings = Array(warnings)
    end

    def error(message) = errors << message.to_s

    def info(message) = infos << message.to_s

    def warn(message) = warnings << message.to_s

    def passed? = errors.empty?

    def to_h
      {
        errors: errors,
        infos: infos,
        warnings: warnings
      }
    end
  end
end
