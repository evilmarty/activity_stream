class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
      t.string :verb, :null => false, :limit => 24
      t.references :actor, :polymorphic => true
      t.references :object, :polymorphic => true
      t.string :context, :limit => 32
      t.datetime :timestamp, :null => false
    end
  end

  def self.down
    drop_table :activities
  end
end
