# frozen_string_literal: true

require 'i2w/data_object'
require 'active_model/conversion'

module I2w
  # base model class, an immutable data object with your app specific behaviour, but no database behaviour, nor
  # input/validation behaviour.  Typically instantiated by a Repo singleton object for persisted models.
  #
  # includes ActiveModel Conversion and Naming
  #
  # it is anticipated that you will create your own application model for persisted classes as follows:
  #
  # class ApplicationModel < I2w::Model::Persisted
  #   # application wide code shared by all persisted models
  # end
  #
  # You may create aggregate, or non persisted models by inheriting from I2w::Model, or adding another base class
  class Model < DataObject::Immutable
    extend Repo::Base.extension :model,
                                to_base: proc { _1 },
                                from_base: proc { _1 }

    extend ActiveModel::Naming
    include ActiveModel::Conversion

    def persisted?
      false
    end

    alias to_hash attributes
    alias to_h attributes

    # a standard rails persisted model with :id pkey and timestamps
    class Persisted < Model
      attribute :id
      attribute :updated_at
      attribute :created_at

      def persisted?
        true
      end
    end
  end
end
