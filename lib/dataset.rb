# One of the two collections of summaries the ministry publishes: 'budget' is what each
# region approved for the year, 'actual' what it later reported having spent. They live in
# two separate applications on the ministry's site, but the pages have the same layout, so
# nothing downstream tells them apart -- only the folders and file names differ.
class Dataset
  NAMES = %w[budget actual].freeze

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
end
