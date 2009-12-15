ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

require 'test/unit'
require 'yaml'
require 'rubygems'
require 'active_record'
require 'active_record/version'
require 'active_record/fixtures'

require File.join(File.dirname(__FILE__), '..', 'init.rb')

def load_schema
  config = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))
  ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), "/debug.log"))

  db_adapter = ENV['DB']

  # no db passed, try one of these fine config-free DBs before bombing.
  db_adapter ||=
    begin
      require 'rubygems'
      require 'sqlite'
      'sqlite'
    rescue MissingSourceFile
      begin
        require 'sqlite3'
        'sqlite3'
      rescue MissingSourceFile
      end
    end

  if db_adapter.nil?
    raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."
  end

  ActiveRecord::Base.establish_connection(config[db_adapter])
  load(File.join(File.dirname(__FILE__), "schema.rb"))
end

def load_fixtures
  filepath = File.join(File.dirname(__FILE__), 'fixtures')
  ActiveSupport::Dependencies.load_paths.unshift filepath
  Fixtures.create_fixtures(filepath, ActiveRecord::Base.connection.tables)
end

def load_activity_model
  template_path = File.join(File.dirname(__FILE__), '..', 'generators', 'activity_stream', 'templates')
  
  load(File.join(template_path, 'migrate', 'create_activities.rb'))
  CreateActivities.up
  
  load(File.join(template_path, 'models', 'activity.rb'))
end