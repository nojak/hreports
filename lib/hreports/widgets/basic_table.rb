module Hreports
  module Widgets
    class BasicTable < BaseWidget
      def initialize(opt = {})
        super(opt)

        @headers = []
        @rows    = []
        @current_row = 0
      end

      def add_header_column(text, cell_opts = {})
        cell_opts[:text] = text
        cell_opts.delete(:x) if cell_opts[:x]
        cell_opts.delete(:y) if cell_opts[:y]
        cell_opts[:width]       ||= @cell_width
        cell_opts[:height]      ||= @cell_height
        cell_opts[:h_align]     ||= :center
        cell_opts[:under_score] ||= true
        cell_opts[:fill_color]  ||= Hreports::Colors::GRAY
        cell_opts[:without_check_overflow] ||= true # セル単位のオーバーフローチェックはしない。
        @headers << cell_opts
      end

      def add_row
        @rows << []
        @current_row = @rows.size - 1
      end

      def add_cell(text, cell_opts = {})
        cell_opts[:text] = text
        cell_opts.delete(:x) if cell_opts[:x]
        cell_opts.delete(:y) if cell_opts[:y]
        cell_opts[:width]  ||= @cell_width
        cell_opts[:height] ||= @cell_height
        cell_opts[:without_check_overflow] ||= true # セル単位のオーバーフローチェックはしない。
        @rows[@current_row] << cell_opts
      end

      def draw(canvas = nil, opt = {})
        return false unless canvas

        # 自動ページ送りした際に、ヘッダを追加描画するかどうかのフラグ
        header_per_page = opt[:header_per_page] ? opt[:header_per_page] : false

        # テーブルヘッダ描画
        draw_headers(canvas)

        # テーブル本体描画
        current_x = @x
        @rows.each do |row|
          inc_row_size = 0
          row.each do |row_opts|
            inc_row_size = row_opts[:height] if inc_row_size < row_opts[:height]
            if canvas.check_vertical_orverflow(row_opts[:height])
              canvas.add_page
              draw_headers(canvas) if header_per_page
            end
            canvas.draw_cell(row_opts[:text], 
                             row_opts.merge(:x => current_x,
                                            :width  => row_opts[:width],
                                            :height => row_opts[:height]))
            current_x += row_opts[:width]
          end
          canvas.row_increment(inc_row_size)
          current_x = @x
        end
      end

      private

      def draw_headers(canvas)
        # ヘッダ描画
        current_x = @x
        inc_row_size = 0
        @headers.each do |header_opts|
          inc_row_size = header_opts[:height] if inc_row_size < header_opts[:height]
          canvas.add_page if canvas.check_vertical_orverflow(header_opts[:height])
          canvas.draw_cell(header_opts[:text],
                           header_opts.merge(:x => current_x,
                                             :width  => header_opts[:width],
                                             :height => header_opts[:height]))
          current_x += header_opts[:width]
        end
        canvas.row_increment(inc_row_size)
      end
    end
  end
end