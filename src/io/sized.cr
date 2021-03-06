module IO
  # An IO that wraps another IO, setting a limit for the number of bytes that can be read.
  #
  # ```
  # io = MemoryIO.new "abcde"
  # sized = IO::Sized.new(io, read_size: 3)
  #
  # sized.gets_to_end # => "abc"
  # sized.gets_to_end # => nil
  # io.gets_to_end    # => "de"
  # ```
  class Sized
    include IO

    # If `sync_close` is true, closing this IO will close the underlying IO.
    property? sync_close : Bool

    # The number of remaining bytes to be read.
    getter read_remaining : UInt64
    getter? closed : Bool

    # Creates a new `IO::Sized` which wraps *io*, and can read a maximum of
    # *read_size* bytes. If *sync_close* is set, calling `#close` calls
    # `#close` on the underlying IO.
    def initialize(@io : IO, read_size : Int, @sync_close = false)
      raise ArgumentError.new "negative read_size" if read_size < 0
      @closed = false
      @read_remaining = read_size.to_u64
    end

    def read(slice : Slice(UInt8))
      check_open

      count = {slice.size.to_u64, @read_remaining}.min
      bytes_read = @io.read slice[0, count]
      @read_remaining -= bytes_read
      bytes_read
    end

    def read_byte
      check_open

      if @read_remaining > 0
        byte = @io.read_byte
        @read_remaining -= 1 if byte
        byte
      else
        nil
      end
    end

    def write(slice : Slice(UInt8))
      raise IO::Error.new "Can't write to IO::Sized"
    end

    def close
      return if @closed
      @closed = true

      @io.close if @sync_close
    end
  end
end
