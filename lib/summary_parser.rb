require 'csv'

require_relative 'summary_page'

# Turns a folder of staged pages into the CSV that DVMI reads.
class SummaryParser
  # Header expected by Javascript in DVMI. Note it sorts before every data row, which start
  # with a year, so it survives the sort below in first place.
  HEADER = '#year,region_id,region_label,policy_id,policy_label,1,2,3,4,5,6,7,8,9,total'.freeze

  attr_reader :input_folder, :output_path

  def initialize(input_folder, output_path)
    @input_folder = input_folder
    @output_path = output_path
  end

  # Writes the CSV and returns how many data rows it holds
  def run
    lines = pages.flat_map(&:rows).map { |row| CSV.generate_line(row) }.sort
    File.write(output_path, "#{HEADER}\n#{lines.join}")
    lines.size
  end

  private

  # In name order, which Dir.glob has guaranteed since Ruby 3.0. It matters: a parser that
  # keeps the first (or the last) description it sees for a code makes its output depend on
  # the order the files arrive in.
  def pages
    Dir.glob(File.join(input_folder, '*.html')).map { |path| SummaryPage.new(path) }
  end
end
