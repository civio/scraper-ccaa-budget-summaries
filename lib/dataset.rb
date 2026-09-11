# One of the two collections of summaries the ministry publishes: 'budget' is what each
# region approved for the year, 'actual' what it later reported having spent. They live in
# two separate applications on the ministry's site, but the pages have the same layout, so
# nothing downstream tells them apart -- only the folders and file names differ.
class Dataset
  NAMES = %w[budget actual].freeze

  BASE_URL = 'https://serviciostelematicosext.hacienda.gob.es/SGCIEF'.freeze

  # The application each dataset lives in, and the name of its landing page. Both
  # applications serve the summaries from a page called Consulta_CFuncionalDCD.aspx:
  # 'Clasificación funcional por capítulos depurados IFL y PAC'.
  SITES = {
    'budget' => %w[PublicacionPresupuestos inicio.aspx],
    'actual' => %w[PublicacionLiquidaciones menuInicio.aspx]
  }.freeze

  attr_reader :name

  # The dataset with this name, or nil
  def self.[](name)
    new(name) if NAMES.include?(name)
  end

  def initialize(name)
    @name = name
  end

  # Where `fetch` leaves the downloaded pages, and where `parse` looks for them
  def staging_folder
    "staging_#{name}"
  end

  # The published CSV. Sorted, so a new run can be diffed against it to spot any error or
  # anomaly, which is what the file name has always said.
  def output_file
    "#{name}.sorted.csv"
  end

  # The page a caller has to go through before the site will serve it any data
  def start_page
    application, landing_page = SITES.fetch(name)
    "#{BASE_URL}/#{application}/aspx/#{landing_page}"
  end

  # The summary for one region and year. The region is the ministry's own number, zero
  # padded, which is also what ends up in the staged file name.
  def data_page(region, year)
    application, = SITES.fetch(name)
    "#{BASE_URL}/#{application}/aspx/Consulta_CFuncionalDCD.aspx?cente=#{region}&ano=#{year}"
  end
end
