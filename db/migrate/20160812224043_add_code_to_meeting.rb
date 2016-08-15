class AddCodeToMeeting < ActiveRecord::Migration
  def change
    add_column :meetings, :checkin_code, :string
  end
end
