require File.join(File.dirname(__FILE__), 'test_helper.rb')

class ActivityStreamTest < ActiveSupport::TestCase  
  load_schema
  load_fixtures
  load_activity_model
  
  def test_model_actor_setup
    assert @person = Person.first
    assert_respond_to @person, :log_activity
    assert_respond_to @person, :activities
  end
  
  def test_model_activity_setup
    assert @comment = Comment.first
    assert_respond_to Comment, :log_activities
    assert_respond_to Comment, :activity_callbacks
    assert_instance_of Hash, Comment.activity_callbacks
    assert_equal true, Comment.activity_callbacks[:after_create]
    assert_instance_of Proc, Comment.activity_callbacks[:after_update]
    assert_instance_of Proc, Comment.activity_callbacks[:after_destroy]
    assert_equal 1, Comment.count_observers
  end
  
  def test_activity_observer
    assert_respond_to ActivityObserver, :instance
  end
  
  def test_log_activity
    assert @person = Person.first
    assert_equal Activity.count, 0
    @person.log_activity do
      @comment = @person.comments.build(:message => "I'm going to leave an activity")
      assert @comment.save
    end
    assert @activity = Activity.first
    assert_equal @activity.actor, @person
    assert_equal @activity.object, @comment
  end
end