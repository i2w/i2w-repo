# frozen_string_literal: true

module I2w
  module Record
    module Concerns
      module TableName
        extend ActiveSupport::Concern

        module ClassMethods
          # remove '_records' suffix from computed table_name
          def table_name
            unless defined?(@table_name)
              super
              @table_name = @table_name.sub(/_records\z/, '').pluralize if @table_name.match?(/_records\z/)
            end
            @table_name
          end
        end
      end
    end
  end
end

