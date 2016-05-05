class Mappru::Logger < ::Logger
  include Singleton

  def initialize
    super($stdout)

    self.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    self.level = Logger::INFO
  end

  def set_debug(value)
    self.level = value ? Logger::DEBUG : Logger::INFO
  end

  module Helper
    def log(level, message, log_options = {})
      global_option = @options || {}
      message = "[#{level.to_s.upcase}] #{message}" unless level == :info
      message << ' (dry-run)' if global_option[:dry_run]
      message = message.send(log_options[:color]) if log_options[:color]
      logger = global_option[:logger] || Mappru::Logger.instance
      logger.send(level, message)
    end
  end
end
