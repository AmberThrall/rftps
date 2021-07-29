# frozen_string_literal: true

require_relative 'pi/server'
require_relative 'pi/client'

# Contains the PI server program
module PI
  # FTP Return Codes
  module ResponseCodes
    INITIATED = 100
    FILE_STATUS_OKAY_OPENING_DATA_CONNECTION = 150
    SUCCESS = 200
    COMMAND_NOT_IMPLEMENTED_BUT_OKAY = 202
    SYSTEM_STATUS = 211
    SYSTEM_TYPE = 215
    SERVICE_READY = 220
    CLOSING_CONNECTION = 221
    FILE_ACTION_SUCCESSFUL = 226
    LOGGED_IN = 230
    OKAY = 250
    PATHNAME_CREATED = 257
    NEED_MORE_INFO = 300
    USER_OKAY_NEED_PASS = 331
    NEED_ACCT = 332
    REQUESTED_FILE_ACTION_PENDING = 350
    TRY_AGAIN = 400
    CANT_OPEN_CONNECTION = 425
    CONNECTION_CLOSED = 426
    SYNTAX_ERROR = 500
    PARAMETER_SYNTAX_ERROR = 501
    COMMAND_NOT_IMPLEMENTED = 502
    BAD_COMMAND_SEQ = 503
    COMMAND_NOT_IMPLEMENTED_FOR_PARAMETER = 504
    NOT_LOGGED_IN = 530
    FILE_UNAVAILABLE = 550
    FILE_ACTION_ABORTED = 551
    INTEGRITY = 600
  end
end
