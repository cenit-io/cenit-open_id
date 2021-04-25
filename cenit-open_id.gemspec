require_relative 'lib/cenit/open_id/version'

Gem::Specification.new do |spec|
  spec.name          = "cenit-open_id"
  spec.version       = Cenit::OpenId.version
  spec.authors       = ["Maikel Arcia"]
  spec.email         = ["mac@cenit.io"]

  spec.summary       = %q{OpenID endpoints to authenticate users.}
  spec.description   = %q{Provide an OpenID wrapper for several OAuth authentication providers.}
  spec.homepage      = "https://cenit.io"
  spec.license       = "MIT"
end
