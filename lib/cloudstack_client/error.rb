module CloudstackClient
  class Error < StandardError; end
  class ParameterError < Error; end
  class ConnectionError < Error; end
  class ConfigurationError < Error; end
  class ParseError < Error; end
  class ApiError < Error; end
  class JobError < Error; end
  class TimeoutError < Error; end
  class InputError < Error; end
end
