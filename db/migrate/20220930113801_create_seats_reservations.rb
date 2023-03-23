class CreateSeatsReservations < ActiveRecord::Migration[6.1]
  def change
    create_table :reservations_seats, :id => false do |t|
      t.integer :seat_id
      t.integer :reservation_id

      t.timestamps null: false
    end
  end
end
