require_relative 'test_helper'

# Reparses every staged page and checks it still produces exactly the published CSV. The
# tests above cover the parsing of a page; this one covers fourteen thousand rows of real
# output, which is the only thing that catches a change in nokogiri, in libxml2, or in what
# the ministry decided to serve us this year.
#
# The staged pages are in the repository, so unlike its equivalent in the Presupuestos
# Generales del Estado scraper this runs everywhere, CI included, with nothing to download.
class GoldenOutputTest < Minitest::Test
  include TestHelper

  Dataset::NAMES.each do |name|
    define_method("test_#{name}_reparses_to_the_published_file") do
      dataset = Dataset[name]
      published = File.join(ROOT, dataset.output_file)

      Dir.mktmpdir do |folder|
        produced = File.join(folder, dataset.output_file)
        SummaryParser.new(File.join(ROOT, dataset.staging_folder), produced).run

        assert_equal_files published, produced
      end
    end
  end

  private

  def assert_equal_files(published, produced)
    expected = File.readlines(published)
    actual = File.readlines(produced)

    refute_empty actual, "#{File.basename(produced)} came out with nothing in it"

    # Deliberately not assert_equal, which appends its own diff of the two arrays to whatever
    # message it is given: on files this size that is a megabyte of output for a one line
    # change. Plain `assert` uses only the message it is handed, and takes it as a block, so
    # `report` only runs when there is something to report.
    # rubocop:disable-next Minitest/AssertEqual, Minitest/AssertOperator, Minitest/AssertWithExpectedArgument
    assert expected == actual, -> { report(published, expected, actual) }
  end

  # Which lines actually appeared or disappeared, rather than the whole file
  def report(published, expected, actual)
    only_published = expected - actual
    only_produced = actual - expected
    details = ["  #{only_published.size} line(s) only in the published file, " \
               "#{only_produced.size} only in the new run",
               *first_difference(expected, actual),
               *samples(only_published, 'only in the published file'),
               *samples(only_produced, 'only in the new run')]

    "#{File.basename(published)} changed (#{expected.size} lines published, " \
      "#{actual.size} produced):\n#{details.join("\n")}"
  end

  def first_difference(expected, actual)
    line = expected.zip(actual).index { |a, b| a != b }
    return [] if line.nil?

    ["  first difference at line #{line + 1}:",
     "    published: #{expected[line].inspect}",
     "    produced:  #{actual[line].inspect}"]
  end

  def samples(lines, where)
    lines.first(3).map { |line| "    #{where}: #{line.inspect}" }
  end
end
