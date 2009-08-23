require 'net/http'
require "rexml/document"

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# Class containing weather observations and forecasts for the location specified by id in the constructor.
class WeatherReport
  
  VERSION = '0.0.2'
  
  # The id is the number (1..9999) the BBC uses to identify cities for weather reports 
  attr_reader :id

  # Raised when there is no response from the server
  class NoResponseError < StandardError
  end
  
  # Raised when the data returned from BBC is not in the expected format
  class FormatError < StandardError
  end
  
  # Requires a valid BBC Backstage weather id (or any call to the API will return a FormatError)
  def initialize(location_id)
    @id = location_id
  end
  
  # Returns the weather observation for the current id. If one is not currently loaded then this will go to the BBC Backstage API and download it.
  # Alternatively, by specifying force_reload = true the observation will be loaded from the BBC regardless of whether one has already been downloaded.
  def observation(force_reload = false) 
    @observation = WeatherReportObservation.new(fetch(observation_url())) if force_reload or @observation.nil?
    @observation
  end
  
  # Returns the weather forecast for the current id. If one is not currently loaded then this will go to the BBC Backstage API and download it.
  # Alternatively, by specifying force_reload = true the observation will be loaded from the BBC regardless of whether one has already been downloaded.
  def forecast(force_reload = false) 
    @forecast = WeatherReportForecasts.new(fetch(forecast_url())) if force_reload or @forecast.nil?
    @forecast
  end
  
  protected
  
  # Fetch Response from the api
  def fetch(url)
    response = Net::HTTP.get_response(URI.parse(url)).body
    
    # Check if a response was returned at all
    raise(WeatherReport::NoResponseError, "WeatherReport Error: No Response.") unless response
     
    response
  end
  
  # The url for getting current weather observations from BBC Backstage
  def observation_url() 
    "http://newsrss.bbc.co.uk/weather/forecast/#{@id}/ObservationsRSS.xml"
  end
    
  # The url for getting weather forecasts from BBC Backstage
  def forecast_url() 
    "http://newsrss.bbc.co.uk/weather/forecast/#{@id}/Next3DaysRSS.xml"
  end
  
end

# Module to load and provide accessors for shared location specific 
module Location

  TITLE = /(.+) for ([\w -\.]*), ([\w -\.]*)/
  
  attr_reader :name, :country, :latitude, :longtitude
  
  # load the location based data (name, country, latitude, longtitude) from the backstage feed
  def loadLocation(xmlDoc)
    xmlDoc.elements.each("rss/channel/title") { |element| 
      md = TITLE.match(element.text)
      @name = md[2] if md 
      @country = md[3] if md 
    }
          
    xmlDoc.elements.each("rss/channel/item[1]/geo:lat") { |element| @latitude = element.text.to_f }
    xmlDoc.elements.each("rss/channel/item[1]/geo:long") { |element| @longtitude = element.text.to_f }
  end
end

# The current weather observations (at least at the time of reading - given by attribute reading_date)
class WeatherReportObservation
  include Location

  DESCRIPTION = /Temperature: ([-\d\.]+|N\/A|NA|\(none\))(.+)Wind Direction: ([\w -\/\(\)]*), Wind Speed: ([-\d\.]+|N\/A|NA|\(none\))mph, Relative Humidity: ([\d\.]+|N\/A|NA|\(none\))(.*), Pressure: ([\d\.]+|N\/A|NA|\(none\))mB, ([\w -\/]+), Visibility: ([\w -\/]+)/
  SUMMARY = /(.+):(\W+)([\w -\/\(\)]+). (.+)/m
  
  attr_reader :temperature, :wind_direction, :wind_speed, :visibility, :pressure, :pressure_state, :humidity, :reading_date, :description

  # Constructs the weather observation from an XML string or file containing the XML in BBC Backstage weather format
  def initialize(document)
    doc = REXML::Document.new document
    
    loadLocation(doc)
    @reading_date = DateTime.now
    doc.elements.each("rss/channel/item[1]/title[1]") { |element| 
      md = SUMMARY.match(element.text)
      @description = md[3]
    }
      
    hasDesc = false
    doc.elements.each("rss/channel/item[1]/description[1]") { |element| 
      hasDesc = true
      md = DESCRIPTION.match(element.text)
      @temperature = md[1].to_f
      @wind_direction = md[3]
      @wind_speed = md[4].to_f * 1.61
      @humidity = md[5].to_f
      @pressure = md[7].to_f
      @pressure_state = md[8]
      @visibility = md[9]
    }
    raise WeatherReport::FormatError unless hasDesc
    
    rescue
      raise WeatherReport::FormatError
  end
  
end

# A collection of forecasts for a particular location
class WeatherReportForecasts < Array
  include Location
  
  attr_reader :reading_date, :image_url
  
  # Constructs the weather forecasts from an XML string or file containing the XML in BBC Backstage weather format
  def initialize(document)
    doc = REXML::Document.new document
    @reading_date = DateTime.now
    loadLocation(doc)
    doc.elements.each("rss/channel/image/url") { |element| @image_url = element.text }
    
    doc.elements.each("rss/channel/item/") { |element| 
      self << WeatherReportForecast.new(element)
    }
    
    raise WeatherReport::FormatError if length == 0
    
    rescue
      raise WeatherReport::FormatError
  end
  
  # Returns the forecast for today, or nil is there is no such forecast.
  def for_today
    self.for(Date.today)
  end
  
  # Returns the forecast for tomorrow, or nil is there is no such forecast.
  def for_tomorrow
    self.for(Date.today+1)
  end
  
  # Returns a forecast for a day given by a Date, DateTime, Time, or a string that can be parsed to a date. 
  # If there is no forecast for the given date then nil is returned.
  def for(date = Date.today)
    date = case date.class.name
           when 'String'
             Date.parse(date)
           when 'Date'
             date
           when 'DateTime'
             Date.new(date.year, date.month, date.day)
           when 'Time'
             Date.new(date.year, date.month, date.day)
           end
    
    day = nil
    self.each do |fd|
      day = fd if date == fd.date
    end
    return day
  end
  
  # A forecast for a single day
  class WeatherReportForecast 
    
    SUMMARY = /([\w -\/]+): ([\w -]+|N\/A|NA|\(none\)), Max Temp: (.*)/m
    DESCRIPTION = /Max Temp: ([-\d\.]+|N\/A|NA|\(none\))(.+)Min Temp: ([-\d\.]+|N\/A|NA|\(none\))(.+)Wind Direction: ([\w -\/\(\)]*), Wind Speed: ([-\d\.]+|N\/A|NA|\(none\))mph, Visibility: ([\w -\/]+), Pressure: ([\d\.]+|N\/A|NA|\(none\))mB, Humidity: ([\d\.]+|N\/A|NA|\(none\))(.*), (.+)/m

    attr_reader :max_temperature, :min_temperature, :wind_direction, :wind_speed, :visibility, :pressure, :humidity, :date, :description, :advance_days

    # Constructs the single day forecast from an REXML element containing the forecast in BBC Backstage weather format
    def initialize(item)
      item.elements.each("title[1]") { |element| 
        md = SUMMARY.match(element.text)
        @description = md[2]
        @advance_days = day_diff(md[1])
        raise(WeatherReport::FormatError, "WeatherReport Error: Day mismatch.") if @advance_days.nil?
        @date = Date.today+@advance_days 
      }
        
      item.elements.each("description[1]") { |element| 
        md = DESCRIPTION.match(element.text)
        @max_temperature = md[1].to_f
        @min_temperature = md[3].to_f
        @wind_direction = md[5]
        @wind_speed = md[6].to_f * 1.61
        @visibility = md[7]
        @pressure = md[8].to_f
        @humidity = md[9].to_f
      }
    end
    
    protected
    
    # Calculate the number of days the given day name is from today's day name assuming it is no more than 5 days in the future or no further back than yesterday.
    # Eg. If today is Wednesday, then if passed Tuesday this function will return -1, if passed Friday it will return 2, and if passed Wednesday it will return 0.
    def day_diff(day_from) 
      start = Date::DAYNAMES.index(day_from.downcase.gsub!(/^[a-z]|\s+[a-z]/) { |a| a.upcase })
      return if start.nil?
      finish = Date.today.wday
      result =  start - finish
      result = result+7 if result < -1
      result = result-7 if result >5
      result
    end
    
  end
  
end