# :stopdoc:
# Copyright (c) 2023 M.J.N. Corino, The Netherlands
#
# This software is released under the MIT license.


# Wx Xml Resource
#
# Documentation stubs for Wx Xml Resource classes
# :startdoc:



module Wx

  # Abstract base class for XRC subclass factories.
  # Derived classes **must** override the #create method (base implementation returns nil).
  class XmlSubclassFactory

    # Factory method to create an object of the specified subclass.
    # @param [String] subclass subclass name
    # @return [Wx::Object] created subclass instance
    def create(subclass) end

  end

end
