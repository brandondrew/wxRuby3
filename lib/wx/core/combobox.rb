
require_relative './controlwithitems'

class Wx::ComboBox
  alias :get_item_data :get_client_data
  alias :set_item_data :set_client_data
end
