class ConvertTrackEntryTagsToArrays < ActiveRecord::Migration[8.1]
  def up
    change_column :track_entries, :genre, :string, array: true, default: [], null: false,
                  using: "(CASE WHEN genre IS NULL THEN '{}' ELSE ARRAY[genre] END)"
    change_column :track_entries, :mood, :string, array: true, default: [], null: false,
                  using: "(CASE WHEN mood IS NULL THEN '{}' ELSE ARRAY[mood] END)"
    add_column :track_entries, :identified, :boolean, default: false, null: false
  end

  def down
    remove_column :track_entries, :identified
    change_column :track_entries, :mood, :string, array: false, default: nil, null: true,
                  using: "array_to_string(mood, ',')"
    change_column :track_entries, :genre, :string, array: false, default: nil, null: true,
                  using: "array_to_string(genre, ',')"
  end
end
