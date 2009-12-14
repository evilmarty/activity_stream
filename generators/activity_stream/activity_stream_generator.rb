class ActivityStreamGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file 'models/activity.rb', 'app/models/activity.rb'
      m.migration_template 'migrate/create_activities.rb', 'db/migrate'
    end
  end
  
  def file_name
    'create_activities'
  end
end