module Hreports
  module Widgets
    class BaseWidget
      def initialize(opt = {})
        @x = opt[:x] ? opt[:x] : 0
        @cell_width  = opt[:cell_width]  ? opt[:cell_width]  : 1
        @cell_height = opt[:cell_height] ? opt[:cell_height] : 1
      end

      def draw(canvas = nil, opt = {})
        # implement here...
      end
    end
  end
end

