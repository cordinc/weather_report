require File.dirname(__FILE__) + '/test_helper.rb'

class TestWeatherReport < Test::Unit::TestCase

  def setup
  end
  
  def test_truth
    w = WeatherReport.new(92)
    assert_not_nil(w)
    assert_equal(w.id, 92)
  end
  
  def test_fine_observation
    obs = WeatherReportObservation.new(File.read(File.dirname(__FILE__) + '/BBC_ObservationsRSS.rss'))
    assert_not_nil(obs)
    assert_equal(obs.name, "Perth")
    assert_equal(obs.country, "Australia")
    assert_equal(obs.latitude, -31.93)
    assert_equal(obs.longtitude, 115.97)
    assert_equal(obs.temperature, 15)
    assert_equal(obs.wind_direction, "SW")
    assert_equal(obs.wind_speed, 1.61)
    assert_equal(obs.visibility, "Very good")
    assert_equal(obs.pressure, 1026)
    assert_equal(obs.pressure_state, "rising")
    assert_equal(obs.humidity, 52)
  end
  
  def test_no_wind_observation
    obs = WeatherReportObservation.new(File.read(File.dirname(__FILE__) + '/BBC_no_wind_ObservationsRSS.rss'))
    assert_not_nil(obs)
    assert_equal(obs.name, "Perth")
    assert_equal(obs.country, "Australia")
    assert_equal(obs.latitude, -31.93)
    assert_equal(obs.longtitude, 115.97)
    assert_equal(obs.temperature, 10)
    assert_equal(obs.wind_direction, "")
    assert_equal(obs.wind_speed, 0)
    assert_equal(obs.visibility, "Excellent")
    assert_equal(obs.pressure, 1025)
    assert_equal(obs.pressure_state, "falling")
    assert_equal(obs.humidity, 63)
  end
  
  def test_error_observation
    assert_raise(WeatherReport::FormatError) { WeatherReportObservation.new(File.read(File.dirname(__FILE__) + '/error.rss'))}
  end
  
  def test_error_forecast
    assert_raise(WeatherReport::FormatError) { WeatherReportForecasts.new(File.read(File.dirname(__FILE__) + '/error.rss'))}
  end
  
  def test_moved_forecast
    assert_raise(WeatherReport::FormatError) { WeatherReportForecasts.new(File.read(File.dirname(__FILE__) + '/moved.rss'))}
  end
  
  def test_moved_observation
    assert_raise(WeatherReport::FormatError) { WeatherReportObservation.new(File.read(File.dirname(__FILE__) + '/moved.rss'))}
  end
  
  def test_current_forecast
    doc = File.read(File.dirname(__FILE__) + '/BBC_Next3DaysRSS.rss')
    doc = doc.gsub("<TODAY>", Date::DAYNAMES[Date.today.wday]).gsub("<TOMORROW>", Date::DAYNAMES[(Date.today+1).wday]).gsub("<DAY_AFTER_TOMORROW>", Date::DAYNAMES[(Date.today+2).wday])
    f = WeatherReportForecasts.new(doc)
    assert_equal(f.name, "Perth")
    assert_equal(f.country, "Australia")
    assert_equal(f.latitude, -31.93)
    assert_equal(f.longtitude, 115.95)
    
    assert_equal(f.for_today.max_temperature, 28)
    assert_equal(f.for_today.min_temperature, 14)
    assert_equal(f.for_today.wind_direction, "ENE")
    assert_equal(f.for_today.wind_speed, 9.66)
    assert_equal(f.for_today.visibility, "very good")
    assert_equal(f.for_today.pressure, 1026)
    assert_equal(f.for_today.humidity, 30)
    
    assert_equal(f.for_tomorrow.max_temperature, 27)
    assert_equal(f.for_tomorrow.min_temperature, 14)
    assert_equal(f.for_tomorrow.wind_direction, "ENE")
    assert((f.for_tomorrow.wind_speed - 11.27).abs < 0.01)
    assert_equal(f.for_tomorrow.visibility, "very good")
    assert_equal(f.for_tomorrow.pressure, 1028)
    assert_equal(f.for_tomorrow.humidity, 33)
    
    assert_equal(f.for(Date.today+2).max_temperature, 25)
    assert_equal(f.for(Date.today+2).min_temperature, 14)
    assert_equal(f.for(Date.today+2).wind_direction, "ENE")
    assert_equal(f.for(Date.today+2).wind_speed, 14.49)
    assert_equal(f.for(Date.today+2).visibility, "very good")
    assert_equal(f.for(Date.today+2).pressure, 1028)
    assert_equal(f.for(Date.today+2).humidity, 37)
    
    assert_nil(f.for(Date.today+3))
    assert_nil(f.for(Date.today-1))
  end
  
  def test_shift_back_forecast
    doc = File.read(File.dirname(__FILE__) + '/BBC_Next3DaysRSS.rss')
    doc = doc.gsub("<TODAY>", Date::DAYNAMES[(Date.today-1).wday]).gsub("<TOMORROW>", Date::DAYNAMES[Date.today.wday]).gsub("<DAY_AFTER_TOMORROW>", Date::DAYNAMES[(Date.today+1).wday])
    f = WeatherReportForecasts.new(doc)
     
    assert_equal(f.for(Date.today-1).max_temperature, 28)
    assert_equal(f.for(Date.today).max_temperature, 27)
    assert_equal(f.for(Date.today+1).max_temperature, 25)
    assert_nil(f.for(Date.today+2))
    assert_nil(f.for(Date.today-2))
  end
  
  def test_shift_forward_forecast
    doc = File.read(File.dirname(__FILE__) + '/BBC_Next3DaysRSS.rss')
    doc = doc.gsub("<TODAY>", Date::DAYNAMES[(Date.today+1).wday]).gsub("<TOMORROW>", Date::DAYNAMES[(Date.today+2).wday]).gsub("<DAY_AFTER_TOMORROW>", Date::DAYNAMES[(Date.today+3).wday])
    f = WeatherReportForecasts.new(doc)
     
    assert_equal(f.for_tomorrow.max_temperature, 28)
    assert_equal(f.for(Date.today+2).max_temperature, 27)
    assert_equal(f.for(Date.today+3).max_temperature, 25)
    assert_nil(f.for_today)
    assert_nil(f.for(Date.today+4))
  end

end
