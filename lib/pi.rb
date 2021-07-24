# frozen_string_literal: true

require_relative 'pi/server'
require_relative 'pi/client'

# Contains the PI server program
module PI
  # FTP Return Codes
  module ResponseCodes
    SERVICE_READY = 220
  end
end
