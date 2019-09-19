require 'active_record'
require 'active_record/relation'
require 'polyamorous'
require 'baby_squeel/version'
require 'baby_squeel/errors'
require 'baby_squeel/active_record/base'
require 'baby_squeel/active_record/query_methods'
require 'baby_squeel/active_record/calculations'
require 'baby_squeel/active_record/where_chain'

module BabySqueel
  class << self
    # Configures BabySqueel using the given block
    def configure
      yield self
    end

    # Turn on BabySqueel's compatibility mode. This will
    # make BabySqueel act more like Squeel.
    def enable_compatibility!
      require 'baby_squeel/compat'
      BabySqueel::Compat.enable!
    end

    # Get a BabySqueel table instance.
    #
    # ==== Examples
    #     BabySqueel[Post]
    #     BabySqueel[:posts]
    #     BabySqueel[Post.arel_table]
    #
    def [](thing, **kwargs)
      if thing.respond_to?(:model_name)
        Relation.new(thing)
      elsif thing.kind_of?(Arel::Table)
        Table.new(thing)
      else
        Table.new(Arel::Table.new(thing, **kwargs))
      end
    end
  end
end

ActiveSupport.on_load :active_record do
  ::ActiveRecord::Base.extend BabySqueel::ActiveRecord::Base
  class ::ActiveRecord::Relation
    prepend BabySqueel::ActiveRecord::QueryMethods
    prepend BabySqueel::ActiveRecord::Calculations
  end
  class ::ActiveRecord::QueryMethods::WhereChain
    prepend BabySqueel::ActiveRecord::WhereChain
  end
end
