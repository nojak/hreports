module Hreports
  module Utils
    module_function

    # 表示する値を適切な表記に変換する
    def convert_value(value)
      return value.strftime("%Y/%m/%d") if value.is_a?(ActiveSupport::TimeWithZone)
      return int_to_c(value) if value.is_a?(Integer)
      return value
    end
    
    # 数値を3桁毎にカンマ区切りする
    def int_to_c(num)
      str = num.to_s
      tmp = ""
      while str =~ /([-+]?.*\d)(\d\d\d)/
        str = $1
        tmp = ",#{$2}" + tmp
      end
      return str + tmp
    end
  end
end