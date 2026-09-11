source 'https://rubygems.org'

ruby '>= 3.2'

# Parsing the summary pages
gem 'nokogiri'

# A bundled gem since Ruby 3.4, so it has to be declared explicitly
gem 'csv'

group :development, :test do
  gem 'minitest'

  # Run in CI. `require: false` because nothing in the project loads these, they are
  # commands: bundle-audit checks the lockfile against the advisory database, and rubocop
  # holds the code to a standard.
  gem 'bundler-audit', require: false
  gem 'rubocop', require: false
  gem 'rubocop-minitest', require: false
end
