module Hreports
  module Widgets
    class VerticalTable < BaseWidget
      def initialize(opt = {})
        super(opt)

        @rows = []
        @current_row = 0
      end

      def add_row
        @rows << []
        @current_row = @rows.size - 1
      end

      def add_column(type = :header, text = "", column_opt = {})
        column_opt[:text] = text
        column_opt[:width] ||= @cell_width
        column_opt[:height] ||= @cell_height
        column_opt.delete(:x) if column_opt[:x]
        column_opt.delete(:y) if column_opt[:y]

        case type
        when :header
          column_opt[:fill_color] ||= Hreports::Colors::GRAY
          column_opt[:h_align] ||= :center
        when :data
          column_opt[:fill_color] ||= Hreports::Colors::WHITE
          column_opt[:h_align] ||= :left
        end

        @rows[@current_row] << column_opt
      end

      def draw(canvas = nil, opt = {})
        @rows.each do |columns|
          current_x = @x
          inc_row_size = 0
          columns.each do |column_opts|
            inc_row_size = column_opts[:height] if inc_row_size < column_opts[:height]
            canvas.draw_cell(column_opts[:text],
                             column_opts.merge(:x => current_x,
                                            :width  => column_opts[:width],
                                            :height => column_opts[:height]))
            current_x += column_opts[:width]
          end
          canvas.row_increment(inc_row_size)
        end
      end
    end
  end
end