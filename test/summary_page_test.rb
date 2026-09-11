require_relative 'test_helper'

# What one staged page turns into. The ministry has changed the site under us more than once
# over twenty years, so these pin down the things that have actually bitten: which region a
# page belongs to, which year, and which of its rows are data.
class SummaryPageTest < Minitest::Test
  include TestHelper

  def test_reads_the_region_from_the_file_name
    # Not from the page, which spells the region's name differently from one year to the next
    assert_equal 1, page(ANDALUCIA).ministry_region_id
    assert_equal 18, page(CEUTA).ministry_region_id
  end

  # The ministry and the INE number the regions the same way right up to Comunitat
  # Valenciana, which the ministry files last and the INE files tenth, shifting everything
  # in between. Population comes from the INE, so the INE's number is the one we publish.
  def test_translates_the_ministry_numbering_into_the_ine_one
    assert_equal 10, page(VALENCIA).ine_region_id
    assert_equal 'Comunidad Valenciana', page(VALENCIA).region_label

    assert_equal 11, page(EXTREMADURA).ine_region_id
    assert_equal 'Extremadura', page(EXTREMADURA).region_label
  end

  def test_the_numbering_only_disagrees_about_that_one_region
    displaced = Regions::INE_CODES_AND_LABELS.each_with_index.reject { |(ine, _), ministry| ine == ministry }

    assert_equal [10, 11, 12, 13, 14, 15, 16, 17], displaced.map(&:last)
  end

  def test_reads_the_year_from_the_page_rather_than_the_file_name
    assert_equal '2025', page(ANDALUCIA).year
    assert_equal '2023', page(CATALUNA_SPENDING).year
  end

  def test_keeps_only_the_rows_with_a_policy_and_a_total
    # 33 <tr> on the page: a header, the expense-area subtotals, and 22 actual policies
    assert_equal 22, page(ANDALUCIA).rows.size
  end

  def test_publishes_the_same_columns_for_both_datasets
    assert_equal(
      ['2023', 9, 'Cataluña', '11', 'Justicia', '422925415.24', '205352010.97', '76337.63',
       '78415060.66', '', '23170309.30', '', '35043.93', '', '729974177.73'],
      page(CATALUNA_SPENDING).rows.first
    )
  end

  # The pages say charset=iso-8859-1 and arrive as UTF-8. Getting this wrong does not fail,
  # it just quietly writes mojibake into twenty years of data.
  def test_the_accents_come_out_right
    labels = page(ANDALUCIA).rows.map { |row| row[4] }

    assert_includes labels, 'Educación'
    assert_includes labels, 'Industria y Energía'
    assert(labels.all? { |label| label.encoding == Encoding::UTF_8 && label.valid_encoding? })
  end

  def test_amounts_lose_the_thousands_separator_and_gain_a_decimal_point
    row = with_page('01_2025.html', a_page, &:rows).first

    assert_equal '1234.56', row[5]
  end

  # Since 2013 the site has answered for Ceuta and Melilla with a table whose cells are all
  # empty, rather than with the 404 it used to return
  def test_a_page_whose_table_is_empty_has_no_rows
    assert_empty page(CEUTA).rows
  end

  def test_the_country_total_is_fetched_but_never_published
    assert_equal 0, page(SPAIN).ine_region_id
    assert_empty page(SPAIN).rows
  end

  def test_expense_area_subtotals_are_left_out
    rows = with_page('01_2025.html', a_page(rows: [SUBTOTAL_ROW, DATA_ROW]), &:rows)

    assert_equal(['11'], rows.map { |row| row[3] })
  end

  def test_years_before_2006_are_left_out
    assert_empty with_page('01_2005.html', a_page(year: 2005), &:rows)
  end

  def test_an_error_page_has_no_rows
    assert_empty with_page('01_2025.html', '<html><body>Se ha producido un error</body></html>', &:rows)
  end

  def test_complains_when_the_heading_carries_no_year
    page_without_a_year = a_page(heading: 'ÁREAS Y POLÍTICAS DE GASTO')

    rows = nil
    _, stderr = capture_io { rows = with_page('01_2025.html', page_without_a_year, &:rows) }

    assert_empty rows
    assert_match(/can't read metadata/, stderr)
  end
end
