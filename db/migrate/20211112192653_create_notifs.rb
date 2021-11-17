class CreateNotifs < ActiveRecord::Migration[6.1]
  def change
    create_table :notifs do |t|
      t.string :user_id
      t.string :email
      t.string :sms
      t.string :timezone

      t.timestamps
    end

    add_index :notifs, :user_id, unique: true
  end
end
