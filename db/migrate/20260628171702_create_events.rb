class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.datetime :held_on
      t.string :venue
      t.string :dj_name

      t.timestamps
    end
  end
end
