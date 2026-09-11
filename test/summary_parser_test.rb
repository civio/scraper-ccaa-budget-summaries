require_relative 'test_helper'

# The shape of the published file. It is read by the Javascript in DVMI, and compared by hand
# against the previous run to spot anomalies, so both the header and the ordering are part of
# the contract rather than incidental.
class SummaryParserTest < Minitest::Test
  include TestHelper

  def test_writes_the_header_dvmi_expects
    assert_equal '#year,region_id,region_label,policy_id,policy_label,1,2,3,4,5,6,7,8,9,total',
                 parse('01_2025.html' => a_page).first
  end

  def test_a_folder_with_nothing_to_publish_still_gets_its_header
    assert_equal 1, parse('18_2020.html' => a_page(rows: [])).size
  end

  def test_writes_one_line_per_row
    lines = parse('01_2025.html' => a_page, '02_2025.html' => a_page)

    assert_equal 3, lines.size
    assert_equal ['2025,1,Andalucía,11,Justicia,1234.56,"","","","","","","","",1234.56',
                  '2025,2,Aragón,11,Justicia,1234.56,"","","","","","","","",1234.56'],
                 lines.drop(1)
  end

  # The sort used to happen in the shell, which meant the published file depended on the
  # locale of whoever ran it. Ruby compares strings byte by byte, which is what LC_ALL=C sort
  # does, and is what the published files have always been sorted by.
  def test_sorts_by_bytes_whichever_order_the_pages_arrive_in
    lines = parse('17_2025.html' => a_page, '02_2025.html' => a_page).drop(1)

    assert_equal lines.sort, lines
    # ...which puts region 10 before region 2, because it is comparing text and not numbers
    assert_equal([10, 2], lines.map { |line| line.split(',')[1].to_i })
  end

  def test_ignores_anything_that_is_not_a_page
    pages = { '01_2025.html' => a_page, 'notes.txt' => a_page, '.gitignore' => a_page }

    assert_equal 2, parse(pages).size
  end

  def test_reports_how_many_rows_it_wrote
    with_pages('01_2025.html' => a_page) do |folder|
      Dir.mktmpdir do |output|
        assert_equal 1, SummaryParser.new(folder, File.join(output, 'out.csv')).run
      end
    end
  end

  private

  # Parses a folder built from `pages` and returns the lines of the CSV it wrote
  def parse(pages)
    with_pages(pages) do |folder|
      Dir.mktmpdir do |output|
        path = File.join(output, 'out.csv')
        SummaryParser.new(folder, path).run
        File.readlines(path, chomp: true)
      end
    end
  end
end
