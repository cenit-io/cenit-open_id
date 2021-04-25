module Cenit
  module OpenId
    module_function

    def version
      Gem::Version.new VERSION::STRING
    end

    module VERSION
      MAJOR = 0
      MINOR = 0
      TINY  = 1

      STRING = [MAJOR, MINOR, TINY].compact.join('.')
    end
  end
end
