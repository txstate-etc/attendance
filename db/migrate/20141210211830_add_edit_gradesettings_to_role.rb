class AddEditGradesettingsToRole < ActiveRecord::Migration
  class Role < ActiveRecord::Base
  end
  class Siterole < ActiveRecord::Base
  end

  def change
    add_column :roles, :edit_gradesettings, :boolean, null: false, default: 0

    Role.reset_column_information
    Siterole.reset_column_information
    role = Role.find_by_roletype('Instructor')
    if role
      role.edit_gradesettings = true
      role.save
      Siterole.where(:role_id => role.id).update_all(:edit_gradesettings => true)
    end
    role = Role.find_by_roletype('Learner/Instructor')
    if role
      role.edit_gradesettings = true
      role.save
      Siterole.where(:role_id => role.id).update_all(:edit_gradesettings => true)
    end
    role = Role.find_by_roletype('TeachingAssistant')
    if role
      role.edit_gradesettings = true
      role.save
      Siterole.where(:role_id => role.id).update_all(:edit_gradesettings => true)
    end
  end
end
