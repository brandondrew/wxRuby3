
class Wx::Clipboard

  alias :place :set_data
  alias :fetch :get_data

  # Opens the global clipboard and passes the clipboard object to the block.
  # @yieldparam [Wx::Clipboard] clip the global clipboard object
  # @return [Object] block result
  def self.open; end

end
