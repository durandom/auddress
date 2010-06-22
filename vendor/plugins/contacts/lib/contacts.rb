module Contacts
  class FetchingError < RuntimeError
    attr_reader :response, :request
    
    def initialize(response, request = nil)
      @response = response
      @request = request
      super "expected HTTPSuccess, got #{response.class} (#{response.code} #{response.message})"
    end
  end
end

require 'contacts/google'