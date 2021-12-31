# frozen_string_literal: true

module I2w
  # represents a looked up class that is missing.  This allows for default dependencies to be declared, and no
  # error occurs until the class is used.  A missing class can be used to look up other related classes
  class MissingClass
    attr_reader :class_names

    def initialize(*class_names)
      @class_names = class_names
    end

    def class_name = class_names.last

    def also_tried = class_names[0..-2]

    def ==(other) = other.is_a?(self.class) && class_names == other.class_names

    alias eql? ==

    def to_s = class_name

    def inspect
      "#<Missing class: #{class_name}#{also_tried.any? ? " (also tried: #{also_tried.join(', ')})" : ''}>"
    end
  end
end