# encoding: utf-8

require 'rubygems'
require 'nokogiri'
require 'csv'
require 'iconv'

def clean_number(s)
  s.delete('.').gsub(',','.')
end

# Always some encoding black magic needed :/ I think the source is wrong (or I screwed up)
def to_UTF8(s)
  Iconv.iconv("iso-8859-1", "utf-8", s).first.force_encoding('UTF-8')
end

# Unfortunately the region ID in the Ministry of Finance site is not the same
# as the region ID in the INE site (where we get population from). The latter
# seems more 'official', so we're using that.
# Note: we used the region name inside the content initially, but there are several
# different spellings per region in the source data 🤷‍♂️, it's a mess.
def get_INE_code(region_id)
  region_id_to_INE_id = [
    0,  # Total
    1,  # Andalucía
    2,  # Aragón
    3,  # Asturías
    4,  # Baleares
    5,  # Canarias
    6,  # Cantabria
    7,  # Castilla León
    8,  # Castilla La Mancha
    9,  # Cataluña
    11, # Extremadura
    12, # Galicia
    13, # Madrid
    14, # Murcia
    15, # Navarra
    16, # Euskadi
    17, # Rioja
    10, # Comunidad Valenciana => This is out of order!
    18, # Ceuta
    19, # Melilla
  ]
  return region_id_to_INE_id[region_id]
end

def parse_file(filename)
  doc = Nokogiri::HTML(open(filename, "r:ISO-8859-1"))
  
  # I thought the CA name was a good key, but turns out it changes sligthly
  # with time. So we'll use the original id instead, part of the filename
  filename =~ /\/(\d\d)\_/
  region_id = get_INE_code($1.to_i)
  
  # First, get the metadata about the file from the first chunk of text
  title = doc.css('h1')[0]
  return if title.nil? # Some error pages
  title.text.strip =~ /EJERCICIO +(\d\d\d\d)/
  year = $1

  # The fetching script used to ensure that the page contained data, since it
  # received a 404 for unavailable years. Now, instead, the site returns an empty table,
  # so we need to be ready to stop parsing when we find one of those.
  return if doc.css('h3')[0].nil?
  
  # ...make sure it's fine...
  if year.nil? or year.empty?
    $stderr.puts "ERROR: can't read metadata for file [#{filename}]"
    return
  end

  # ...and then, process all the rows...
  doc.css('tr').each do |r|
    # ...but look only at the ones with the data
    columns = r.css('td')
    next if columns.size!=12
  
    # ...and ignore the subtotal rows
    policy_id = columns.shift.text
    policy_label = to_UTF8(columns.shift.text).strip
  
    # Extract the values from remaining columns
    values = columns.map {|c| clean_number(c.text.strip)}
  
    # And output. Note: at the moment we just care about what gets shown in the DVMI region 
    # visualization, so we ignore a bunch of stuff. We display only:
    #  - region id is enough, name not needed.
    #  - only for years after (and including) 2006
    #  - only for actual regions, ignore the total
    #  - only non-zero chapter-level data, ignore 'expense area' subtotals
    if year.to_i >= 2006 and region_id != 0 and policy_id =~ /\d\d/ and !values.last.empty?
      data = [year, region_id, policy_id, policy_label]
      0.upto(9) {|i| data.push(values[i]) }
      puts CSV::generate_line(data)
    end
  end
end

puts '#year,region_id,policy_id,policy_label,1,2,3,4,5,6,7,8,9,total'  # Header expected by Javascript in DVMI

# Parse all files in the given staging folder
Dir["#{ARGV[0]}/*html"].each {|filename| parse_file(filename)}
