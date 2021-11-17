# takes timestamp (with miliseconds) and zone name like 'Europe/Warsaw'
# and returns DateTime
class ZonedFromJsStamp
  def self.call(timestamp, zone_name)
    Time.at(timestamp / 1000).in_time_zone(zone_name).to_datetime
  end
end
