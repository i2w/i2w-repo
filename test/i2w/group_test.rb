require 'test_helper'

class I2w::GroupTest < ActiveSupport::TestCase
  class Model
    def self.group_name = name

    def self.group_type = :model

    def self.from_group_name(group_name) = group_name.constantize
  end

  class Input
    def self.group_name = name.sub(/Input\z/, '')

    def self.group_type = :input

    def self.from_group_name(group_name) = "#{group_name}Input".constantize
  end

  class Dog < Model; end

  class DogInput < Input; end

  class SmellyDogInput < Input
    def self.group_name = 'I2w::GroupTest::Dog'
  end

  test '.lookup for classes with user defined class_group methods' do
    classes = I2w::Group.new
    classes.registry[:model] = Model
    classes.registry[:input] = Input

    assert_equal Dog, classes.lookup(DogInput, :model)
    assert_equal Dog, classes.lookup(SmellyDogInput, :model)
    assert_equal Dog, classes.lookup('I2w::GroupTest::Dog', :model)
  end
end
