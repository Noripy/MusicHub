class CreateTrackEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :track_entries do |t|
      t.references :event, null: false, foreign_key: true
      t.string :title
      t.string :genre
      t.string :mood
      t.integer :bpm
      t.text :memo

      t.timestamps
    end
  end
end
