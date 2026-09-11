require 'nokogiri'

require_relative 'regions'

# One staged page: the 'clasificación funcional por capítulos depurados IFL y PAC' for a
# single region and year, exactly as the ministry served it.
#
# A word on the encoding, because it looks wrong and is not. The pages declare
# `charset=iso-8859-1` in a meta tag and are actually served as UTF-8 bytes. So the page is
# read as ISO-8859-1 on purpose, which mis-decodes it, and `to_utf8` below re-encodes each
# character back to the byte it came from and relabels the result. Reading the page as binary
# and letting Nokogiri believe the meta tag -- the right thing to do with most of the
# ministry's sites -- would mangle every accent here.
class SummaryPage
  # The region number is part of the file name. The name inside the page is not usable: it
  # changes slightly with time.
  REGION_IN_FILENAME = /\A(\d\d)_/

  # A data row has twelve cells: the policy id and its name, then the nine expense chapters
  # and the total. Anything else on the page is a heading or an expense-area subtotal.
  DATA_COLUMNS = 12

  # DVMI only shows the years from 2006 on
  FIRST_YEAR = 2006

  attr_reader :path

  def initialize(path)
    @path = path
  end

  # Everything on this page worth publishing, as arrays ready for CSV. Empty when the page
  # holds no data, which happens more often than you would think: see `data?` below.
  def rows
    return [] unless data?

    document.css('tr').filter_map { |row| row_values(row) }
  end

  # The ministry's number for the region this page describes, taken from the file name
  def ministry_region_id
    File.basename(path)[REGION_IN_FILENAME, 1].to_i
  end

  def ine_region_id
    ine_code_and_label.first
  end

  def region_label
    ine_code_and_label.last
  end

  # The year in the page's own heading, which is the one to trust over the file name, or nil
  # when the ministry served an error page instead
  def year
    return @year if defined?(@year)

    heading = document.css('h1')[0]
    @year = heading && heading.text.strip[/EJERCICIO +(\d\d\d\d)/, 1]
  end

  private

  # Whether there is anything here to parse. Three ways there is not:
  #
  #  * no heading at all, which is what an error page looks like;
  #  * no <h3> either, which is the site's way of saying it has no data for this region and
  #    year. The fetching script used to catch that as a 404, but recent versions of the site
  #    return an empty table instead;
  #  * a heading we cannot read the year out of, which has never happened but would quietly
  #    misfile a whole page if it did, so it is worth a complaint on stderr.
  def data?
    return false if document.css('h1')[0].nil?
    return false if document.css('h3')[0].nil?

    if year.nil? || year.empty?
      warn "ERROR: can't read metadata for file [#{path}]"
      return false
    end

    true
  end

  # One row of the table, or nil when it is not a row we publish
  def row_values(row)
    columns = row.css('td').map(&:text)
    return nil unless columns.size == DATA_COLUMNS

    policy_id, policy_label, *amounts = columns
    values = amounts.map { |amount| clean_number(amount.strip) }
    return nil unless publish?(policy_id, values)

    [year, ine_region_id, region_label, policy_id, to_utf8(policy_label).strip] + values
  end

  # At the moment we just care about what gets shown in the DVMI region visualization, so we
  # ignore a bunch of stuff. We display only:
  #  - region id is enough, name not needed.
  #  - only for years after (and including) 2006
  #  - only for actual regions, ignore the total
  #  - only non-zero chapter-level data, ignore 'expense area' subtotals
  def publish?(policy_id, values)
    year.to_i >= FIRST_YEAR && ine_region_id != Regions::TOTAL &&
      policy_id =~ /\d\d/ && !values.last.empty?
  end

  def document
    @document ||= Nokogiri::HTML(File.read(path, encoding: 'ISO-8859-1'))
  end

  def ine_code_and_label
    @ine_code_and_label ||= Regions.ine_code_and_label(ministry_region_id)
  end

  def clean_number(string)
    string.delete('.').gsub(',', '.')
  end

  # Always some encoding black magic needed :/ I think the source is wrong (or I screwed up)
  def to_utf8(string)
    string.encode('iso-8859-1').force_encoding('utf-8')
  end
end
