require 'activity_stream'
require 'activity_observer'

ActiveRecord::Base.class_eval { include ActivityStream::ActiveRecord }
ActiveRecord::Associations::AssociationProxy.class_eval { include ActivityStream::AssociationProxy }
ActiveRecord::Associations::BelongsToAssociation.class_eval { include ActivityStream::BelongsToAssociation }
ActiveRecord::Associations::HasOneAssociation.class_eval { include ActivityStream::HasOneAssociation }
ActiveRecord::Associations::HasManyAssociation.class_eval { include ActivityStream::HasManyAssociation }
ActiveRecord::Associations::BelongsToPolymorphicAssociation.class_eval { include ActivityStream::BelongsToPolymorphicAssociation }