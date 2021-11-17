require "rails_helper"

RSpec.describe Booking, type: :model do # TODO: use fixtures, or better, factorybot
  let(:day) { Time.new(2021, 11, 21).to_date }
  let(:day_str) { "2021-11-21" }
  let(:clear) { -> { Booking.all.each(&:delete) } }

  after { clear.call }

  it "checks avaliability (all cases except finish=nil)" do
    Booking.quick_read(day_str, "12:30", "13:00").save

    expect(Booking.free_at?(TimeUtils.fill_date_of_read_time(day, "11:30", nosec: true),
      TimeUtils.fill_date_of_read_time(day, "12:00", nosec: true))).to be true
    expect(Booking.free_at?(TimeUtils.fill_date_of_read_time(day, "13:30", nosec: true),
      TimeUtils.fill_date_of_read_time(day, "14:00", nosec: true))).to be true

    expect(Booking.free_at?(TimeUtils.fill_date_of_read_time(day, "12:20", nosec: true),
      TimeUtils.fill_date_of_read_time(day, "12:40", nosec: true))).to be false # overlaps at end
    expect(Booking.free_at?(TimeUtils.fill_date_of_read_time(day, "12:45", nosec: true),
      TimeUtils.fill_date_of_read_time(day, "13:15", nosec: true))).to be false # moverlaps at beggining
    expect(Booking.free_at?(TimeUtils.fill_date_of_read_time(day, "12:25", nosec: true),
      TimeUtils.fill_date_of_read_time(day, "13:05", nosec: true))).to be false # encloses
  end

  it "checks avaliability with finish=nil" do
    Booking.quick_read(day_str, "12:00", "12:05").save
    Booking.quick_read(day_str, "13:00").save

    expect(Booking.free_at?(TimeUtils.fill_date_of_read_time(day, "11:20", nosec: true),
      TimeUtils.fill_date_of_read_time(day, "11:25", nosec: true))).to be true
    expect(Booking.free_at?(TimeUtils.fill_date_of_read_time(day, "12:20", nosec: true),
      TimeUtils.fill_date_of_read_time(day, "12:25", nosec: true))).to be true

    expect(Booking.free_at?(TimeUtils.fill_date_of_read_time(day, "13:40", nosec: true),
      TimeUtils.fill_date_of_read_time(day, "13:45", nosec: true))).to be false
  end

  it "ignores seconds" do
    b = Booking.quick(Time.new(2021, 11, 21).to_date, Time.new(2021, 11, 21, 10, 20, 10).to_datetime,
      Time.new(2021, 11, 21, 10, 30, 30).to_datetime)
    b.save

    expect(b.booked.sec).to eq(0) # no seconds
    expect(b.released.sec).to eq(0) # no seconds
  end

  it "allows 1 minute overlap" do
    Booking.quick(Time.new(2021, 11, 21).to_date, Time.new(2021, 11, 21, 10, 20).to_datetime,
      Time.new(2021, 11, 21, 10, 30).to_datetime).save
    Booking.quick(Time.new(2021, 11, 21).to_date, Time.new(2021, 11, 21, 10, 45).to_datetime,
      Time.new(2021, 11, 21, 10, 55).to_datetime).save
    expect(Booking.free_at?(Time.new(2021, 11, 21, 10, 30).to_datetime,
      Time.new(2021, 11, 21, 10, 45).to_datetime)).to be true # overlap up to 1 minute ignored
  end
end
