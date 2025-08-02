module TableTennis
  module Util
    # static wrapper around IO.console to handle the case where IO.console is nil
    module Console
      module_function

      # supported when IO.console is nil
      def winsize(...)
        IO.console&.winsize(...) || [48, 80]
      end

      # not supported, don't call these
      %i[fileno getbyte raw syswrite].each do |name|
        define_method(name) do |*args, **kwargs, &block|
          if !IO.console
            raise "IO.console.#{name} not supported when IO.console is nil"
          end
          IO.console.send(name, *args, **kwargs, &block)
        end
      end
    end
  end
end
