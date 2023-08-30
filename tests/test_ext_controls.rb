
require_relative './lib/wxframe_runner'
require_relative './lib/text_entry_tests'

class SearchCtrlTests < WxRuby::Test::GUITests

  include TextEntryTests

  def setup
    super
    @search = Wx::SearchCtrl.new(test_frame, name: 'SearchCtrl')
    Wx.get_app.yield
  end

  def cleanup
    @search.destroy
    Wx.get_app.yield
    super
  end

  attr_reader :search
  alias :text_entry :search

  def test_search
    assert_equal('', search.get_value)
  end

end

class CalendarCtrlTests < WxRuby::Test::GUITests

  def setup
    super
    @cal = Wx::CalendarCtrl.new(test_frame, name: 'Calendar')
    Wx.get_app.yield
  end

  def cleanup
    @cal.destroy
    Wx.get_app.yield
    super
  end

  attr_reader :cal

  def test_date
    now = Time.now
    dt = cal.get_date
    assert_not_nil(dt)
    assert((dt.to_i - now.to_i) < 10) # should only be a fraction of a second

    now = Time.now
    assert_nothing_raised { cal.set_date(Wx::DEFAULT_DATE_TIME) }
    now = Time.now
    dt = cal.get_date
    assert_not_nil(dt)
    assert((dt.to_i - now.to_i) < 10) # should only be a fraction of a second
  end

end

class HyperlinkCtrlTests < WxRuby::Test::GUITests

  def setup
    super
    @link = Wx::HyperlinkCtrl.new(test_frame, label: 'Hyperlink', url: 'https://mcorino.github.io/wxRuby3/Wx/HyperlinkCtrl.html', name: 'Hyperlink')
    Wx.get_app.yield
  end

  def cleanup
    @link.destroy
    Wx.get_app.yield
    super
  end

  attr_reader :link

  def test_link
    assert_equal('https://mcorino.github.io/wxRuby3/Wx/HyperlinkCtrl.html', link.get_url)
  end

end
