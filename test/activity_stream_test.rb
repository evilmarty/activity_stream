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
    assert_respond_to Comment, :activity_triggers
    assert_instance_of Hash, Comment.activity_triggers
    assert_equal true, Comment.activity_triggers[:after_create]
    assert_instance_of Proc, Comment.activity_triggers[:after_update]
    assert_instance_of Proc, Comment.activity_triggers[:after_destroy]
    assert_equal 1, Comment.count_observers
  end
  
  def test_activity_observer
    assert_respond_to ActivityObserver, :instance
  end
  
  def test_log_activity
    assert @person = Person.first
    Activity.delete_all
    @person.log_activity do
      @comment = @person.comments.build(:message => "I'm going to leave an activity")
      assert @comment.save
    end
    assert @activity = Activity.first
    assert_equal @person, @activity.actor
    assert_equal @comment, @activity.object
  end
  
  def test_indirect_object
    Activity.delete_all
    assert @person = Person.last
    assert @post = Post.first
    assert @comment = @post.comments.build(:message => 'testing indirect object')
    
    @person.log_activity do
      assert @comment.save
    end
    assert_equal @post, Activity.first.indirect_object
  end
  
  def test_explicit_indirect_object
    Activity.delete_all
    assert @person = Person.last
    assert @post = Post.first
    assert @other_post = Post.last
    assert_not_equal @post, @other_post
    
    @person.log_activity_indirectly_for(@other_post) do
      assert @post.comments.create :message => 'testing explicit indirect'
    end
    assert_equal @other_post, Activity.first.indirect_object
  end
end