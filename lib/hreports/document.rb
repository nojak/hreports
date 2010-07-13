require 'hpdf'

module Hreports
  class Document
    attr_reader :left_margin, :right_margin, :top_margin, :bottom_margin
    attr_reader :left_padding, :right_padding, :top_padding, :bottom_padding
    attr_reader :current_row, :max_col, :max_row
    attr_accessor :default_cell_width, :default_cell_height

    PDF_STORE_PATH = File.join(RAILS_ROOT, 'tmp', 'pdf_store')
    
    def initialize(opt = {})
      x_unit_size  = opt[:x_unit_size]  ? opt[:x_unit_size]  : 10
      y_unit_size  = opt[:y_unit_size]  ? opt[:y_unit_size]  : 40
      margins      = opt[:margins]      ? opt[:margins]      : []
      paddings     = opt[:paddings]     ? opt[:paddings]     : []
      border_width = opt[:border_width] ? opt[:border_width] : 0.7
      uscore_width = opt[:uscore_width] ? opt[:uscore_width] : 0.7

      @pdf   = HPDFDoc.new
      @pages = [@pdf.add_page]
      @current_page_number = 0
      @current_row  = 0
      @max_col = x_unit_size  # X方向最大セルサイズ
      @max_row = y_unit_size  # Y方向最大セルサイズ

      # 日本語フォントを使うためのおまじない。
      @pdf.use_jp_fonts
      @pdf.use_jp_encodings
      @font = @pdf.get_font("MS-Mincyo", "90ms-RKSJ-H")

      # ページマージン及びセルパディング幅の設定（単位：ピクセル）
      @left_margin, @right_margin, @top_margin, @bottom_margin = margins      
      @left_padding, @right_padding, @top_padding, @bottom_padding = paddings

      # ページの横幅上限と縦幅上限の設定（単位：ピクセル）
      @area_width  = current_page.get_width - @left_margin - @right_margin
      @area_height = current_page.get_height - @top_margin - @bottom_margin

      # 単位セルの横幅と縦幅の計算（単位：ピクセル）
      @unit_width  = @area_width  / x_unit_size
      @unit_height = @area_height / y_unit_size

      @default_font_size = 10
      @default_border_width = border_width
      @default_uscore_width = uscore_width

      # いくつのUnitをまとめてデフォルトのCellサイズとするかを定義する
      @default_cell_width  = 1
      @default_cell_height = 1

      @font_color = [0.0, 0.0, 0.0]
    end


    def save(filename = nil)
      Dir.mkdir(PDF_STORE_PATH) unless File.exist?(PDF_STORE_PATH)
      tmp_name = "tmp_pdf_#{Time.now.to_i}_#{srand(Time.now.to_i);rand(10000)}.pdf"
      filename ||= File.join(PDF_STORE_PATH, tmp_name)
      @pdf.save_to_file(filename)
      return filename
    end


    def row_increment(num = nil)
      num ||= @default_cell_height
      unless num.is_a?(Integer)
        raise Hreports::Errors::PDFCreateError, "Invalid font color format."
      end
      @current_row += num
    end

    
    def current_page
      return @pages[@current_page_number]
    end


    def add_page(num = 1)
      num.times do
        @pages << @pdf.add_page
      end
      @current_page_number = @pages.size - 1
      @current_row = 0
    end


    def change_page(num)
      if @pages[num - 1]
        @current_page_number = num - 1
        @current_row  = 0
      end
    end


    def set_font(name, encode)
      @font = @pdf.get_font(name, encode)
    end


    def set_font_size(size)
      @default_font_size = size if size.is_a?(Integer)
    end


    def set_font_color(color = [0.0, 0.0, 0.0])
      unless color.is_a?(Array) && color.size == 3
        raise Hreports::Errors::PDFCreateError, "Invalid font color format."
      end
      @font_color = color
    end


    def draw_cell(text = "", opt = {})
      x = opt[:x] ? opt[:x] : 0
      y = opt[:y] ? opt[:y] : @current_row
      width  = opt[:width]  ? opt[:width]  : @default_cell_width
      height = opt[:height] ? opt[:height] : @default_cell_height

      without_check_overflow = opt[:without_check_overflow] ? opt[:without_check_overflow] : false
      add_page if check_vertical_orverflow(height) && !without_check_overflow

      cell_opt = {:x => x, :y => y, 
                  :width => width, :height => height,
                  :text => text}
      cell_opt.merge!(opt)
      draw_unit(cell_opt)
    end
    

    def draw_text(text = "", opt = {})
      x = opt[:x] ? opt[:x] : 0
      y = opt[:y] ? opt[:y] : @current_row
      width  = opt[:width]  ? opt[:width]  : @max_col
      height = opt[:height] ? opt[:height] : @default_cell_height

      without_check_overflow = opt[:without_check_overflow] ? opt[:without_check_overflow] : false
      add_page if check_vertical_orverflow(height) && !without_check_overflow

      cell_opt = {:x => x, :y => y,
                  :width => width, :height => height,
                  :h_align => :left,
                  :text => text,
                  :without_border => true
                  }
      cell_opt.merge!(opt)
      draw_unit(cell_opt)
      row_increment(height)
    end


    def load_image(filename)
      # 画像形式はPNGのみ対応する。
      # JPEG形式を扱う場合は、load_jpeg_image_from_fileメソッドが適用可能。
      @image_obj = @pdf.load_png_image_from_file(filename)
      return @image_obj
    end

    # PNG画像の表示メソッド
    def draw_image(x, y)
      raise "image unloaded." unless @image_obj
      current_page.draw_image(@image_obj, 
                                x, (current_page.get_height - y),
                                @image_obj.get_width, @image_obj.get_height)
    end


    def page_width
      return current_page.get_width
    end


    def page_height
      return current_page.get_height
    end

    def check_horizontal_orverflow(unit_width, unit_x = nil)
      x, dummy1     = convert_position(:x => unit_x, :y => 0)
      width, dummy2 = convert_position(:x => unit_width, :y => 1,
                                         :without_margin => true)
      if (x + width) > (current_page.get_width - @right_width)
        return true
      else
        return false
      end
    end


    def check_vertical_orverflow(unit_height, unit_y = nil)
      unit_y = @current_row unless unit_y
      dummy1, y      = convert_position(:x => 0, :y => unit_y)
      dummy2, height = convert_position(:x => 1, :y => unit_height,
                                          :without_margin => true)
      if (y - height) < @bottom_margin
        return true
      else
        return false
      end
    end


    private

    def draw_unit(opt = {})
      unit_x         = opt[:x].to_f
      unit_y         = opt[:y].to_f
      unit_width     = opt[:width].to_f
      unit_height    = opt[:height].to_f
      text           = opt[:text].to_s
      font_size      = opt[:font_size]      ? opt[:font_size].to_i    : @default_font_size
      h_alignment    = opt[:h_align]        ? opt[:h_align]           : :left
      v_alignment    = opt[:v_align]        ? opt[:v_align]           : :middle
      without_border = opt[:without_border] ? opt[:without_border]    : false
      under_score    = opt[:under_score]    ? opt[:under_score]       : false
      border_width   = opt[:border_width]   ? opt[:border_width].to_i : @default_border_width
      uscore_width   = opt[:uscore_width]   ? opt[:uscore_width].to_i : @default_uscore_width
      fill_color     = opt[:fill_color]     ? opt[:fill_color]        : [1.0, 1.0, 1.0]
      border         = opt[:border]         ? opt[:border]            : nil
      font_color     = opt[:font_color]     ? opt[:font_color]        : @font_color
      bold           = opt[:bold]           ? opt[:bold]              : false

      x, y = convert_position(:x => unit_x, :y => unit_y)
      width, height = convert_position(:x => unit_width, :y => unit_height,
                                         :without_margin => true)

      unless without_border
        current_page.set_line_width(border_width)
        current_page.set_rgb_fill(fill_color[0], fill_color[1], fill_color[2])

        current_page.rectangle(x, y, width, -height)
        current_page.fill_stroke
        current_page.set_rgb_fill(0.0, 0.0, 0.0)
      end

      current_page.begin_text
      current_page.set_font_and_size(@font, font_size)
      text_width = current_page.text_width(Kconv.tosjis(text))

      h_align = @left_padding
      case h_alignment
      when :center
        h_align = (width / 2) - (text_width * current_page.get_horizontal_scalling / 100 / 2)
      when :right
        h_align = width - text_width * current_page.get_horizontal_scalling / 100 - @right_padding
      end

      v_align = height / 2
      case v_alignment
      when :top
        v_align = font_size + @top_padding + 2
      when :bottom
        v_align = height - @bottom_padding - 2
      when :middle
        v_align = height / 2 + font_size / 2 - @bottom_padding
      end

      if bold
        current_page.set_rgb_stroke(font_color[0], font_color[1], font_color[2])
        current_page.set_text_rendering_mode(HPDFDoc::HPDF_FILL_THEN_STROKE)
      end

      current_page.set_rgb_fill(font_color[0], font_color[1], font_color[2])
      current_page.move_text_pos(x + h_align, y - v_align)
      current_page.show_text(Kconv.tosjis(text))
      current_page.end_text

      if bold
        current_page.set_text_rendering_mode(HPDFDoc::HPDF_FILL)
      end

      if under_score
        current_page.set_line_width(uscore_width)
        current_page.move_to(x + h_align, y - v_align - 2)
        current_page.line_to(x + h_align + text_width, y - v_align - 2)
        current_page.stroke
      end

      if border
        if border.class == "Array"
          border.each do
            | position |
            draw_line(position, border_width, x, y, width, height)
          end
        else
          draw_line(border, border_width, x, y, width, height)
        end
      end

      return nil
    end


    def convert_position(opt = {})
      unit_x = opt[:x] ? opt[:x] : nil
      unit_y = opt[:y] ? opt[:y] : nil
      without_margin = opt[:without_margin] ? opt[:without_margin] : false

      if without_margin
        real_x = @unit_width * unit_x
        real_y = @unit_height * unit_y
        return real_x, real_y
      else
        real_x = (@unit_width * unit_x) + @left_margin
        real_y = current_page.get_height - ((@unit_height * unit_y) + @top_margin)
        return real_x, real_y
      end
    end


    def draw_line(position, border_width, x, y, width, height)
      case position
      when :top
        current_page.set_line_width(border_width)
        current_page.move_to(x -2, y + 2)
        current_page.line_to(x + width + 2, y + 2)
        current_page.stroke
      when :bottom
        current_page.set_line_width(border_width)
        current_page.move_to(x - 2, y - height - 2)
        current_page.line_to(x + width + 2, y - height - 2)
        current_page.stroke
      when :left
        current_page.set_line_width(border_width)
        current_page.move_to(x - 2, y + 2)
        current_page.line_to(x - 2, y - height - 2)
        current_page.stroke
      when :right
        current_page.set_line_width(border_width)
        current_page.move_to(x + width + 2, y + 2)
        current_page.line_to(x + width + 2, y - height - 2)
        current_page.stroke
      end
    end
  end
end