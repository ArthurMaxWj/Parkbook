require 'rails_helper'

RSpec.describe TimeUtils do # TODO: use fixtures, or better, factorybot
  describe '::read_datetime' do
    it 'reads correctly' do
      expect(TimeUtils::read_datetime('2021-03-13 10:30')).to eq(Time.new(2021, 3, 13, 10, 30).to_datetime)
    end
  end

  describe '::read_date' do
    it 'reads correctly' do
      expect(TimeUtils::read_date('2021-03-13')).to eq(Time.new(2021, 3, 13).to_date)
    end
  end

  describe '::read_time' do
    it 'reads correctly' do
      expect(TimeUtils::read_time('10:30')).to eq(Time.new(1, 1, 1, 10, 30))
    end
  end
end
