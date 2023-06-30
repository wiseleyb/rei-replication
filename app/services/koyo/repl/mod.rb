module Koyo::Repl::Mod
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    attr_accessor :koyo_repl_handler_method

    def koyo_repl_handler(n)
      @koyo_repl_handler_method = n
    end
  end
end
