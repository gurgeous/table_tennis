module TableTennis
  module Util
    # Very complicated module for determining the terminal background color,
    # used to select the default color theme.
    module Termbg
      prepend MemoWise

      module_function

      # get fg color as "#RRGGBB", or nil if we can't tel
      def fg = osc_query(10) || env_colorfgbg&.fetch(0)
      memo_wise self: :fg

      # get bg color as "#RRGGBB", or nil if we can't tell
      def bg = osc_query(11) || env_colorfgbg&.fetch(1)
      memo_wise self: :bg

      # mostly for debugging
      def info
        {
          fg:,
          bg:,
          bg_luma: bg ? Colors.luma(bg) : nil,
          tty?: "#{$stdin.tty?}/#{$stdout.tty?}/#{$stderr.tty?}",
          in_foreground?: in_foreground?,
          osc_supported?: osc_supported?,
          "$COLORFGBG": ENV["COLORFGBG"],
          "$TERM": ENV["TERM"],
          colorfgbg: env_colorfgbg,
        }
      end

      #
      # osc_query
      #

      # escape chars
      ESC, BEL, ST, = "\e", "\a", "\e\\"

      # Operating System Control queries
      OSC_FG, OSC_BG = 10, 11

      def osc_supported?
        host, platform, term = [
          RbConfig::CONFIG["host_os"],
          RbConfig::CONFIG["platform"],
          ENV["TERM"],
        ]
        error = if host !~ /darwin|freebsd|linux|netbsd|openbsd/
          "bad host"
        elsif platform !~ /^(arm64|x86_64)/
          "bad platform"
        elsif term =~ /^(screen|tmux|dumb)/i
          "bad TERM"
        elsif ENV["ZELLIJ"]
          "zellij"
        elsif !IO.console
          "no console"
        end
        if error
          debug("osc_supported? #{{host:, platform:, term:}} => #{error}")
          return false
        end
        debug("osc_supported? #{{host:, platform:, term:}} => success")
        true
      end

      def osc_query(attr)
        # let's be conservative
        return if !osc_supported?

        # mucking with the tty will hang if we are not in the foreground
        return if !in_foreground?

        # we can't touch stdout inside IO.console.raw, so save these for later
        logs = []

        debug("osc_query(#{attr})")
        begin
          Util::Console.raw do
            logs << "  IO.console.raw"

            # we send two messages - the cursor query is widely supported, so we
            # always end with that. if the first message is ignored we will still
            # get an answer to the second so we know when to stop reading from stdin
            msg = [].tap do
              # operating system control with Ps=attr
              _1 << "\e]#{attr};?\a"
              # device status report with Ps = 6 (cursor position)
              _1 << "\e[6n"
            end.join

            logs << "  syswrite #{msg.inspect}"
            Util::Console.syswrite(msg)

            # there should always be at least one response. If this is a response to
            # the cursor message, the first message didn't work
            response1 = read_term_response.tap do
              logs << "  got #{_1.inspect}"
              if !(_1 && _1[1] == "]")
                logs << "  not OSC, bailing"
                return
              end
              response2 = read_term_response # skip cursor response
              logs << "  got #{response2.inspect}"
            end
            decoded = decode_osc_response(response1)
            logs << "=> #{decoded}"
            decoded
          end
        ensure
          logs.each { debug(_1) }
        end
      end
      private_class_method :osc_query

      # read a response, which could be either an OSC or cursor response
      def read_term_response
        # fast forward to ESC
        loop do
          return if !(ch = Util::Console.getbyte&.chr)
          break ch if ch == ESC
        end
        # next char should be either [ or ]
        return if !(type = Util::Console.getbyte&.chr)
        return if !(type == "[" || type == "]")

        # now read the response. note that the response can end in different ways
        # and we have to check for all of them
        buf = "#{ESC}#{type}"
        loop do
          return if !(ch = Util::Console.getbyte&.chr)
          buf << ch
          break if type == "[" && buf.end_with?("R")
          break if type == "]" && buf.end_with?(BEL, ST)
        end
        buf
      end
      private_class_method :read_term_response

      #
      # color math
      #

      def decode_osc_response(response)
        if response =~ %r{;rgb:([0-9a-f/]+)}i
          rgb = $1.split("/")
          return if rgb.length != 3
          hex = rgb.join
          return if hex.length % 3 != 0
          Colors.to_hex(Colors.to_rgb(hex))
        end
      end
      private_class_method :decode_osc_response

      #
      # in_foreground?
      #

      # returns true/false or nil (if unknown)
      def in_foreground?
        if !respond_to?(:tcgetpgrp)
          load_ffi!
          return if !respond_to?(:tcgetpgrp)
        end

        io = Util::Console
        if (ttypgrp = tcgetpgrp(io.fileno)) <= 0
          debug("tcpgrp(#{io.fileno}) => #{ttypgrp}, errno=#{FFI.errno}")
          return
        end
        debug("tcpgrp(#{io.fileno}) => #{ttypgrp}")

        # now compare against our process group
        infg = Process.getpgrp == ttypgrp
        debug("Process.getpgrp => #{Process.getpgrp}, in_foreground? #{infg}")
        infg
      end
      private_class_method :in_foreground?
      memo_wise self: :in_foreground?

      def load_ffi!
        module_eval do
          extend FFI::Library
          ffi_lib "c"
          attach_function :tcgetpgrp, %i[int], :int32
          debug("ffi attach libc.tcgetpgrp => success")
        end
      rescue LoadError => ex
        debug("ffi attach libc.tcgetpgrp => failed #{ex.message}")
      end
      private_class_method :load_ffi!
      memo_wise self: :load_ffi!

      def env_colorfgbg(env = ENV["COLORFGBG"])
        if env !~ /^\d+;\d+$/
          debug("env_colorfgbg: COLORFGBG '#{env.inspect}'") if env
          return
        end
        colors = env.split(";").map { Colors.ansi_color_to_hex(_1.to_i) }
        debug("env_colorfgbg: #{env.inspect}' => #{colors.inspect}")
        colors
      end
      private_class_method :env_colorfgbg

      def debug(s)
        puts "termbg: #{s}" if ENV["TT_DEBUG"]
      end
      private_class_method :debug
    end
  end
end

#
# This comment is down here to avoid polluting ruby-lsp hover.
#
# Is the terminal dark or light? To answer this simple question, we need to
# query the terminal to get the current background color.
#
#    https://github.com/dalance/termbg
#    https://github.com/muesli/termenv
#    https://github.com/rocky/shell-term-background
#
# This is absurdly difficult, so here is our approach:
#
# 1. Use OSC 11 to query the bgcolor using a magical escape sequence. We write
#    the escape sequence to stdout and read the response from stdin. Not all
#    terminals support this. Also, the terminal must be in "raw" mode for this
#    to work. Raw mode means disable echo and disable line buffering.
#
#    https://en.wikipedia.org/wiki/ANSI_escape_code
#    https://github.com/ruby/io-console/blob/master/lib/ffi/io/console/common.rb
#    https://www.xfree86.org/4.8.0/ctlseqs.html
#    https://stackoverflow.com/questions/2507337/
#
# 2. Because not all terminals support OSC 11, we actually send two magic escape
#    sequences - OSC 11 and a "where is the cursor" message. Because the second
#    query is universally supported we always get a response. That's how we
#    avoid breaking stdin by over/under reading.
#
# 3. Mucking with the tty can hang (!) under some circumstances, which is a poor
#    outcome for a fun ruby library like this. Only try this if we are "in the
#    foreground". You can easily try this with the following command:
#
#    $ watchexec stty sane                         # this hangs
#    $ watchexec --wrap-process=none stty sane     # this works fine
#
#    https://github.com/watchexec/watchexec/issues/874
#    https://github.com/ruby/io-console
#
# 4. To detect if we are in the foreground, compare the process group against
#    the group the process group that owns stdin. If they match, we are good to
#    go.
#
#    https://unix.stackexchange.com/questions/736821/
#
# 5. Sadly, ruby does not have an easy way to get the process group of stdin.
#    Instead, we have to use ruby-termios, ffi or $stdin.ioctl using a magic
#    ioctl number (this magic number differs across platforms). I went with
#    ffi.
#
#    https://github.com/arika/ruby-termios
#    https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/ioctls.h
#    https://github.com/swiftlang/swift/blob/main/stdlib/public/Platform/TiocConstants.swift
#
# 6. If the foreground is lighter than the background, the background is dark.
#
# 7. As a fallback to OSC 11, we also support $COLORFGBG. Terminals can set this
#    environment variable to communicate colors to apps. Support is spotty,
#    unfortunately. Even when COLORFGBG is set, it is not updated after the
#    terminal is started. So it can be out of date if the user mucks with
#    colors.
#
#    https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
#    https://unix.stackexchange.com/questions/245378/
#    https://www.xfree86.org/4.8.0/XLookupColor.3.html#toc4
#
