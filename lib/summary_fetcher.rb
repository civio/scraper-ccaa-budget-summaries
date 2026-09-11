require 'net/http'
require 'uri'

# Downloads a dataset's summary pages into its staging folder, one file per region and year.
#
# The site will not serve a data page to a caller that turns up cold: ask for one without a
# session and it answers 302, redirecting to the landing page. So the first request here
# exists only to be given a session, and every request after it carries the cookies that came
# back -- an ASP.NET session id and a load balancer's stickiness cookie.
#
# We used to stop at the first missing year, catching the 404 the site returned for one. It
# does not 404 any more: it serves a page with an empty table instead, for any year at all,
# including ones in the future. So every year in the range is downloaded and the parser is
# left to recognise the empty ones.
class SummaryFetcher
  # 0: total, 1: Andalucía... 19: Melilla. We keep the total even though it never reaches the
  # published CSV: it is the cheapest check that a year's figures add up.
  REGIONS = (0..19)

  attr_reader :dataset, :output_folder, :years

  def initialize(dataset, output_folder, years)
    @dataset = dataset
    @output_folder = output_folder
    @years = years
  end

  # Downloads every page, returning how many were saved
  def run
    start = URI.parse(dataset.start_page)

    Net::HTTP.start(start.host, start.port, use_ssl: true) do |http|
      @http = http
      @cookies = session_cookies(start)

      REGIONS.sum { |region| fetch_region(region) }
    end
  end

  private

  # The landing page's only job is to hand out the cookies the data pages ask for
  def session_cookies(start)
    response = @http.get(start.request_uri)
    raise "The landing page at #{start} answered #{response.code}" unless response.is_a?(Net::HTTPOK)

    response.get_fields('set-cookie').to_a.map { |cookie| cookie.split(';').first }.join('; ')
  end

  # Newest year first, which is the order the site itself lists them in
  def fetch_region(region)
    years.reverse_each.count { |year| fetch_page(format('%02d', region), year.to_s) }
  end

  # Saves one page and returns where it went, or nil when the site would not serve it
  def fetch_page(region, year)
    print "Region #{region}, Year #{year}... "
    response = @http.get(URI.parse(dataset.data_page(region, year)).request_uri, 'Cookie' => @cookies)

    unless response.is_a?(Net::HTTPOK)
      # A redirect here means the session was not accepted, so the body would be the landing
      # page rather than a summary. Saving it would quietly poison the staging folder.
      puts response.code
      return nil
    end

    # Binary, because the body is what goes on disk untouched. The pages declare one encoding
    # in a meta tag and arrive in another; SummaryPage is where that gets untangled.
    path = File.join(output_folder, "#{region}_#{year}.html")
    File.binwrite(path, response.body)
    puts 'OK'
    path
  end
end
