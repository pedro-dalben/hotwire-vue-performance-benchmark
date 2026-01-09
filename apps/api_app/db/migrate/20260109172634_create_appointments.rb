class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.string :beneficiary_name
      t.string :professional_name
      t.string :unit_name
      t.datetime :starts_at
      t.string :status
      t.text :notes

      t.timestamps
    end

    add_index :appointments, :starts_at
    add_index :appointments, :status
    add_index :appointments, :unit_name
    add_index :appointments, :beneficiary_name
  end
end
