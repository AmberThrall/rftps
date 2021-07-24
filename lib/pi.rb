# frozen_string_literal: true

require_relative 'pi/server'
require_relative 'pi/client'

# Contains the PI server program
module PI
  # FTP Return Codes
  module ResponseCodes
    INITIATED = 100
    SUCCESS = 200
    SERVICE_READY = 220
    CLOSING_CONNECTION = 221
    NEED_MORE_INFO = 300
    TRY_AGAIN = 400
    SYNTAX_ERROR = 500
    PARAMETER_SYNTAX_ERROR = 501
    COMMAND_NOT_IMPLEMENTED = 502
    INTEGRITY = 600
  end
end
