module Sequel
  # This module makes it easy to add deprecation functionality to other classes.
  module Deprecation # :nodoc:
    # This sets the output stream for the deprecation messages.  Set it to an IO
    # (or any object that responds to puts) and it will call puts on that
    # object with the deprecation message.  Set to nil to ignore deprecation messages.
    def self.deprecation_message_stream=(file)
      @dms = file
    end

    # Set this to true to print tracebacks with every deprecation message,
    # so you can see exactly where in your code the deprecated methods are
    # being called.
    def self.print_tracebacks=(pt)
      @pt = pt
    end

    # Puts the messages unaltered to the deprecation message stream
    def self.deprecate(message)
      if @dms
        @dms.puts(message)
        caller.each{|c| @dms.puts(c)} if @pt 
      end
    end

    # Formats the message with a message that it will be removed in Sequel 2.0.
    # This is the method that is added to the classes that include Sequel::Deprecation.
    def deprecate(meth, message = nil)
      ::Sequel::Deprecation.deprecate("#{meth} is deprecated, and will be removed in Sequel 2.0.#{"  #{message}." if message}")
    end
  end
end
