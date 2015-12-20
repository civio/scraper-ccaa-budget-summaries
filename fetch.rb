# Fetch CCAA expense summary (functional, by chapters)

require 'rubygems'
require 'mechanize'

@agent = Mechanize.new

# Go through the landing page so a 'session' is started, otherwise we'll get rejected later :/
@agent.get('http://serviciosweb.meh.es/apps/publicacionpresupuestos/aspx/inicio.aspx')

# Download data and store into staging folder
def fetch_data(region, year)
  url = "http://serviciosweb.meh.es/apps/publicacionpresupuestos/aspx/Consulta_CFuncionalDC.aspx?cente=#{region}&ano=#{year}"
  print "Region #{region}, Year #{year}... "
  html = @agent.get(url)
  File.open("staging/#{region}.#{year}.txt", 'w') {|f| f.write(html.content) }
  puts "OK"
end

# Get all available data for a given region
def fetch_region(region)
  begin
    # We used to break when one year was missing (the actual year depends on the region)
    # by catching 404s. But most recent versions of the site do not 404, they return
    # an empty table instead, which we'll have to handle downstream.
    2015.downto(2000).each do |year|
      fetch_data("%02d" % region, year.to_s)
    end
  rescue Mechanize::ResponseCodeError => ex
    if ex.response_code == '404'
      puts "Not found"
    else
      puts ex.response_code
    end
  end

end

# Get all available data... 
0.upto(19).each do |region|         # 0: total, 1: Andalucía... 19: Melilla
  fetch_region(region)
end
