class AddIndexOnIdentifiedToTrackEntries < ActiveRecord::Migration[8.1]
  def change
    add_index :track_entries, :identified
  end
end
