# this shouldn't't really be in './lib', but just to show the possibility

module TimeUtils
  DATE_FORMAT = '%m/%d/%Y'
  TIME_FORMAT = '%I:%M %p'
  DATETIME_FORMAT = '%m/%d/%Y %I:%M %p'

  # readers:

  def self.read_datetime(words)
    return nil unless /\d\d-\d\d-\d\d \d\d:\d\d/.match?(words)

    date, time = words.split(' ')

    year, month, day = date.split('-').map(&:to_i)
    hour, sec = time.split(':').map(&:to_i)
    Time.new(year, month, day, hour, sec).to_datetime
  end

  def self.read_date(word)
    return nil unless /\d\d-\d\d-\d\d/.match?(word)

    year, month, day = word.split('-').map(&:to_i)
    Time.new(year, month, day).to_date
  end

  def self.read_time(word)
    return nil unless /\d\d:\d\d/.match?(word)

    hour, sec = word.split(':').map(&:to_i)
    Time.new(1, 1, 1, hour, sec).to_datetime
  end

  # modifiers:

  def self.fill_date_of_time(day, time, nosec: false)
    Time.new(day.year, day.month, day.day, time.hour, time.min, nosec ? 0 : time.sec).to_datetime
  end

  def self.fill_date_of_read_time(day, time, nosec: false)
    time = TimeUtils::read_time(time)
    return nil if time.nil?

    Time.new(day.year, day.month, day.day, time.hour, time.min, nosec ? 0 : time.sec).to_datetime
  end

  def self.nosec(datetime)
    datetime - datetime.sec.seconds
  end

  # formatters:

  def self.format_date(any)
    any.strftime(DATE_FORMAT)
  end

  def self.format_time(any)
    any.nil? ? 'to the end of day' : any.strftime(TIME_FORMAT)
  end

  def self.format_datetime(any)
    any.strftime(DATETIME_FORMAT)
  end
end
