module TableTennis
  # Responsible for building Config objects with proper defaults, detection, and validation
  class ConfigBuilder
    def self.build(options = {}, terminal: nil, &block)
      new(terminal:).build(options, &block)
    end

    def initialize(terminal: nil)
      @terminal = terminal || Terminal.new
    end

    def build(options = {}, &block)
      # Assemble options from defaults and user input
      merged_options = assemble_options(options)

      # Apply auto-detection
      apply_auto_detection!(merged_options)

      # Apply environment overrides
      apply_environment_overrides!(merged_options)

      # Create config with clean options
      Config.new(merged_options, terminal: @terminal, &block)
    end

    private

    def assemble_options(user_options)
      [Config::OPTIONS, TableTennis.defaults, user_options].reduce { |acc, opts| acc.merge(opts || {}) }
    end

    def apply_auto_detection!(options)
      options[:color] = Config.detect_color? if options[:color].nil?
      options[:theme] = Config.detect_theme(@terminal) if options[:theme].nil?
    end

    def apply_environment_overrides!(options)
      options[:debug] = true if ENV["TT_DEBUG"]
    end
  end
end
