module BabySqueel
  module Compat
    # ruby won't let us reopen classes in method bodies so do it here.
    PATCH_CLASSES_PROC = Proc.new do
      class ::BabySqueel::DSL
        prepend Compat::DSL
      end
      class ::ActiveRecord::Base
        class << self
          prepend QueryMethods
        end
      end
      class ::ActiveRecord::Relation
        prepend QueryMethods
      end
    end

    # Monkey-patches BabySqueel and ActiveRecord
    # in order to behave more like Squeel
    def self.enable!
      PATCH_CLASSES_PROC.call
    end

    class KeyPath
      def self.evaluate(&block)
        if block.arity.zero?
          unwrap new.instance_eval(&block)
        else
          unwrap yield(new)
        end
      end

      def self.unwrap(path)
        if path.kind_of? self
          path.value
        elsif path.respond_to? :map
          path.map(&method(:unwrap))
        else
          []
        end
      end

      def initialize(*path)
        @path = path
      end

      def value
        @path.reverse.reduce({}) do |acc, name|
          { name => acc }
        end
      end

      private

      def respond_to_missing?(*)
        true
      end

      def method_missing(name, *)
        self.class.new(*@path, name)
      end
    end

    module DSL
      # An alias for BabySqueel::DSL#sql
      def `(str)
        sql(str)
      end

      # Allows you to call out of an instance_eval'd block.
      def my(&block)
        @caller.instance_eval(&block)
      end

      # Remember the original binding of the block
      def evaluate(&block)
        @caller = block.binding.eval('self')
        super
      end

      private

      def resolver
        @resolver ||= BabySqueel::Resolver.new(self, [:polymorphic_association, :function, :column, :association, :fuzzy_attribute])
      end
    end

    module QueryMethods
      # Overrides ActiveRecord::QueryMethods#joins
      def joins(*args, &block)
        if block_given? && args.empty?
          joining(&block)
        else
          super
        end
      end

      # Overrides ActiveRecord::QueryMethods#includes
      def includes(*args, &block)
        if block_given? && args.empty?
          super KeyPath.evaluate(&block)
        else
          super
        end
      end

      # Overrides ActiveRecord::QueryMethods#eager_load
      def eager_load(*args, &block)
        if block_given? && args.empty?
          super KeyPath.evaluate(&block)
        else
          super
        end
      end

      # Overrides ActiveRecord::QueryMethods#preload
      def preload(*args, &block)
        if block_given? && args.empty?
          super KeyPath.evaluate(&block)
        else
          super
        end
      end

      # Heads up, Array#select conflicts with
      # ActiveRecord::QueryMethods#select. So, if arity
      # is given to the block, we'll use Array#select.
      # Otherwise, you'll be in a DSL block.
      #
      #    Model.select { This is DSL }
      #    Model.select { |m| This is not DSL }
      #
      def select(*args, &block)
        if block_given? && args.empty? && block.arity.zero?
          selecting(&block)
        else
          super
        end
      end

      # Overrides ActiveRecord::QueryMethods#order
      def order(*args, &block)
        if block_given? && args.empty?
          ordering(&block)
        else
          super
        end
      end

      def reorder(*args, &block)
        if block_given? && args.empty?
          reordering(&block)
        else
          super
        end
      end

      # Overrides ActiveRecord::QueryMethods#group
      def group(*args, &block)
        if block_given? && args.empty?
          grouping(&block)
        else
          super
        end
      end

      # Overrides ActiveRecord::QueryMethods#having
      def having(*args, &block)
        if block_given? && args.empty?
          when_having(&block)
        else
          super
        end
      end

      # Overrides ActiveRecord::QueryMethods#where
      def where(*args, &block)
        if block_given? && args.empty?
          where.has(&block)
        else
          super
        end
      end
    end
  end

  class Nodes::FuzzyAttribute < Nodes::Attribute
    private

    def method_missing(name, *args, &block)
      if args.empty?
        begin
          super
        rescue NoMethodError => e
          Nodes::FuzzyAttribute.new(Table.new(::Arel::Table.new(@name)), name)
        end
      else
        super
      end
    end
  end
end
