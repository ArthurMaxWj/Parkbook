class CreateBookings < ActiveRecord::Migration[6.1]
  def change
    create_table :bookings do |t|
      t.integer :position
      t.date :day
      t.datetime :booked
      t.datetime :released
      t.string :user
      t.string :displayed_name

      t.timestamps
    end
  end
end
