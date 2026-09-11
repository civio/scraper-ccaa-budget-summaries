$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'
require 'tmpdir'

require 'dataset'
require 'regions'
require 'summary_page'
require 'summary_parser'

module TestHelper
  ROOT = File.expand_path('..', __dir__)

  # The staged pages are in the repository, so the tests read the real thing rather than a
  # copy of it. These are the ones worth a name:
  ANDALUCIA = 'staging_budget/01_2025.html'.freeze      # an ordinary page
  VALENCIA = 'staging_budget/17_2025.html'.freeze       # the region the two numberings disagree on
  EXTREMADURA = 'staging_budget/10_2025.html'.freeze    # and the one that disagreement displaces
  CEUTA = 'staging_budget/18_2020.html'.freeze          # stopped reporting in 2013, page still served
  SPAIN = 'staging_budget/00_2025.html'.freeze          # the country total, which we fetch but never publish
  CATALUNA_SPENDING = 'staging_actual/09_2023.html'.freeze

  def page(relative_path)
    SummaryPage.new(File.join(ROOT, relative_path))
  end

  # A page the ministry has never served us, for the shapes it might. Both of these return
  # whatever the block returns, so a test can pull one value out and assert on it.
  def with_page(name, contents)
    with_pages(name => contents) { |folder| yield SummaryPage.new(File.join(folder, name)) }
  end

  def with_pages(pages)
    Dir.mktmpdir do |folder|
      pages.each { |name, contents| File.binwrite(File.join(folder, name), contents) }
      yield folder
    end
  end

  # The smallest thing SummaryPage will accept: a heading with the year, the <h3> that says
  # the table is not empty, and one data row of twelve cells.
  def a_page(year: 2025, heading: "ÁREAS Y POLÍTICAS DE GASTO. EJERCICIO #{year}", rows: [DATA_ROW])
    <<~HTML
      <html><head><meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" /></head>
      <body><h1>#{heading}</h1><h3>Comunidad de Prueba</h3>
      <table>#{rows.join}</table></body></html>
    HTML
  end

  # One data row as the ministry writes it: the policy id, its name, the nine expense
  # chapters (all but the first empty here) and the total
  AMOUNTS = ['1.234,56', *Array.new(8, ''), '1.234,56'].freeze
  DATA_ROW = "<tr><td>11</td><td>Justicia</td>#{AMOUNTS.map { |a| "<td>#{a}</td>" }.join}</tr>".freeze

  # What an expense-area subtotal looks like: the same table, fewer cells
  SUBTOTAL_ROW = '<tr><td>1</td><td>Servicios Públicos Básicos</td><td>1.234,56</td></tr>'.freeze
end
