require "./app/services/zoned_from_js_stamp"

class Booking < ApplicationRecord
  validates :position, presence: true
  validates :day, presence: true
  validates :booked, presence: true
  validates :user, presence: true
  validates :displayed_name, presence: true

  # checking availability:

  # checks whether last user released place
  def self.free?(desired_day, position: 1)
    Booking.order(booked: :desc).find_by(day: desired_day, position: position).released?
  end

  # checks whether desired time is free (checks finish = nil as well)
  # Seconds don't matter (set to 00) and minutes can overlap by 1 (booking at the end of last booked minute is ok)
  def self.free_at?(desired_start, desired_finish, position: 1)
    desired_start = TimeUtils.nosec(desired_start)
    desired_finish = TimeUtils.nosec(desired_finish)

    h = Booking.holding(desired_start, position: position)
    unless h.nil?
      h_start = TimeUtils.nosec(h.booked)
      return false if h_start < desired_finish
    end

    Booking.where(
      "((booked BETWEEN :start AND :finish) OR (released BETWEEN :start AND :finish)" \
      " OR (:start >= booked AND :finish <= released)) AND position = :position", # this continues the parentheses from above
      {start: desired_start + 1.minute, finish: desired_finish - 1.minute, position: position}
    ).count == 0
  end

  # checks whether desired time is free (omits finish = nil)
  # Seconds don't matter (set to 00) and minutes can overlap by 1 (booking at the end of last booked minute is ok)
  def self.free_nonil_at?(desired_start, desired_finish)
    desired_start = TimeUtils.nosec(desired_start)
    desired_finish = TimeUtils.nosec(desired_finish)
    Booking.where("(booked BETWEEN :start AND :finish) OR (released BETWEEN :start AND :finish)" \
                  " OR (:start >= booked AND :finish <= released)", # this continues the parentheses from above
      {start: desired_start + 1.minute, finish: desired_finish - 1.minute}).count == 0
  end

  # checks if release is set in particular Booking
  def released?
    !released.nil?
  end

  # sets release of particular Booking
  def release(datetime)
    datetime = TimeUtils.nosec(datetime)

    raise "Attemting to release already released Booking" if released?

    update(released: datetime)
  end

  # returns last booking if unreleased (nil if nonexistent)
  def self.holding(desired_day, position: 1)
    Booking.order(booked: :desc).find_by(position: position, day: desired_day, released: nil)
  end

  # creation of Booking:

  # takes JS timestamps (in milliseconds) and returns Booking object (user data defaults to logged-in)
  def self.from_client_js(timezone:, day_ts:, booked_ts:, released_ts: nil, user: CurrentUser.id, displayed_name: CurrentUser.name, position: 1)
    timezone ||= CurrentUser.timezone
    Booking.new(day: ZonedFromJsStamp.call(day_ts, timezone).to_date,
      booked: ZonedFromJsStamp.call(booked_ts, timezone),
      released: released_ts.nil? ? nil : ZonedFromJsStamp.call(released_ts, timezone),
      user: user, displayed_name: displayed_name, position: position)
  end

  # simplified creation of Booking
  def self.quick(day, start, finish = nil, user: CurrentUser.id, displayed_name: CurrentUser.name, position: 1)
    start = TimeUtils.nosec(start)
    finish = TimeUtils.nosec(finish) unless finish.nil?

    Booking.new(day: day.to_date,
      booked: start,
      released: finish,
      user: user, displayed_name: displayed_name, position: position)
  end

  def self.quick_read(day, start, finish = nil, user: CurrentUser.id, displayed_name: CurrentUser.name, position: 1)
    day = TimeUtils.read_date(day)
    start = TimeUtils.read_time(start)
    raise ArgumentError, "Wrong argument syntax" if day.nil? || start.nil?

    start = TimeUtils.fill_date_of_time(day, start, nosec: true)

    unless finish.nil?
      finish = TimeUtils.read_time(finish)
      raise ArgumentError, "Wrong argument syntax" if finish.nil?

      finish = TimeUtils.fill_date_of_time(day, finish, nosec: true)
    end

    Booking.new(day: day,
      booked: start,
      released: finish,
      user: user, displayed_name: displayed_name, position: 1)
  end

  # zone management:

  # returns a hash with ':day', ':booked' and ':released',
  # containing respective values in timezone 'Booking#timezone'
  # (or given in 1st param)
  def zoneified(timezone = nil)
    timezone ||= Notif::DEFAULT_TIMEZONE

    rel = released.nil? ? nil : released.in_time_zone(timezone)
    {day: day.in_time_zone(timezone).to_date, booked: booked.in_time_zone(timezone), released: rel}
  end

  # shorthand version of 'Booking::zoneified'
  # Returns array with (in order): ':day', ':booked' and ':released'.
  def zoned(timezone = nil)
    z = zoneified(timezone)
    [z[:day], z[:booked], z[:released]]
  end

  def to_s
    "Booking #{TimeUtils.format_date(day)} #{TimeUtils.format_time(booked)}" \
      " to #{TimeUtils.format_time(released)} at [#{z.position}] by '#{displayed_name}'"
  end

  def send_notifs
    Notif.find_by(user_id: @user_id)&.send_notifs(self)
  end
end
