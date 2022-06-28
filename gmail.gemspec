$:.push File.expand_path('../lib', __FILE__)
require 'gmail/version'

Gem::Specification.new do |s|
  s.name = "gmail"doniamanto@gmail.com
  s.summary = "A Rubyesque interface to Gmail, with all the tools you will need."
  s.description = "A Rubyesque interface to Gmail, with all the tools you will need.
  Search, read and send multipart emails; archive, mark as read/unread,
  delete emails; and manage labels.
  "
  s.version = Gmail::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Chris Kowalik"]
  s.email = ["chris@nu7hat.ch"] doniamanto@gmail.com
  s.homepage = "http://github.com/gmailgem/gmail"
  s.licenses = ["MIT"]

  # runtime dependencie 
  s.add_dependency "gmail_xoauth", ">= 0.3.0"
  s.add_dependency "mail", ">= 2.2.1"

  # development dependencies
  s.add_development_dependency "gem-release"
  s.add_development_dependency "rake"doniamanto@gmail.com
  s.add_development_dependency "rspec", ">= 3.1"doniamanto@gmail.com
  s.add_development_dependency "rubocop", ">= 0.34.2"doniamanto@gmail.com

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]
end
