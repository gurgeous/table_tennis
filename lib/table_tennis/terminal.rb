module TableTennis
  # Terminal wrapper class that safely handles IO.console operations
  # and provides fallbacks for CI/non-interactive environments
  class Terminal
    prepend MemoWise

    DEFAULT_WIDTH = 80
    attr_reader :console

    def initialize(console = :auto_detect)
      @console = (console == :auto_detect) ? IO.console : console
    rescue => e
      debug("Failed to detect console: #{e.message}")
      @console = nil
    end

    def width
      safe_operation { @console.winsize[1] } || DEFAULT_WIDTH
    end
    memo_wise :width

    def available? = !@console.nil?
    def fileno = safe_operation { @console.fileno }
    def getbyte = safe_operation { @console.getbyte }

    def raw_operation(fallback = nil, &block)
      safe_operation { @console.raw(&block) } || fallback
    end

    def syswrite(data)
      safe_operation do
        @console.syswrite(data)
        true
      end || false
    end

    def with_console(fallback = nil, &block)
      safe_operation { yield(@console) } || fallback
    end

    # Class methods
    def self.current = @current ||= new
    def self.null = new(nil)
    def self.reset! = @current = nil

    private

    def safe_operation(&block)
      return unless available?
      yield
    rescue => e
      debug("Console operation failed: #{e.message}")
      nil
    end

    def debug(message)
      puts "terminal: #{message}" if ENV["TT_DEBUG"]
    end
  end
end
