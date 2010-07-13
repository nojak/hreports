module Hreports
  module Errors
    class BaseError < Exception; end
    class PDFCreateError < BaseError; end
  end
end