module ReplMod
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    def koyo_repl_handler(n)
      puts "krh: #{n}"
      #send(n, 'qqqqq')
    end
  end
end
