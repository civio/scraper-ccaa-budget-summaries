# The regions, as the ministry numbers them.
#
# Unfortunately the region id in the Ministry of Finance site is not the same as the region
# id in the INE site (where we get population from). The latter seems more 'official', so
# we're using that: the ministry's number identifies the staged page, the INE's is what ends
# up in the published CSV.
#
# Note: we used the region name inside the content initially, but there are several different
# spellings per region in the source data 🤷‍♂️, it's a mess. The number in the file name is
# the only stable key.
module Regions
  # Indexed by the ministry's number, 0: total, 1: Andalucía... 19: Melilla. Each entry is
  # the INE id and the label we publish.
  INE_CODES_AND_LABELS = [
    [0,  'Total'],
    [1,  'Andalucía'],
    [2,  'Aragón'],
    [3,  'Asturías'],
    [4,  'Baleares'],
    [5,  'Canarias'],
    [6,  'Cantabria'],
    [7,  'Castilla León'],
    [8,  'Castilla La Mancha'],
    [9,  'Cataluña'],
    [11, 'Extremadura'],
    [12, 'Galicia'],
    [13, 'Madrid'],
    [14, 'Murcia'],
    [15, 'Navarra'],
    [16, 'Euskadi'],
    [17, 'Rioja'],
    [10, 'Comunidad Valenciana'], # This is out of order!
    [18, 'Ceuta'],
    [19, 'Melilla']
  ].freeze

  # The whole country rather than one region. The ministry publishes it as region 0, and we
  # fetch it, but it is not part of what DVMI shows, so it never reaches the CSV.
  TOTAL = 0

  # The INE id and label for one of the ministry's region numbers.
  def self.ine_code_and_label(ministry_id)
    INE_CODES_AND_LABELS[ministry_id]
  end
end
