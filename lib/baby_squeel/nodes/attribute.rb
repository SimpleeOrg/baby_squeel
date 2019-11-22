require 'baby_squeel/nodes/node'

module BabySqueel
  module Nodes
    class Attribute < Node
      def initialize(parent, name)
        @parent = parent
        @name = name.to_s
        super(parent._table[@name])
      end

      def in(rel)
        rel = rel.flatten if rel.is_a?(Array)
        if rel.is_a? ::ActiveRecord::Relation
          Nodes.wrap ::Arel::Nodes::In.new(self, sanitize_relation(rel))
        elsif rel.is_a?(Array) && rel.include?(nil)
          rel = rel.compact
          rel.empty? ? self.eq(nil) : self.in(rel).or(self.eq(nil))
        else
          super
        end
      end

      def not_in(rel)
        rel = rel.flatten if rel.is_a?(Array)
        if rel.is_a? ::ActiveRecord::Relation
          Nodes.wrap ::Arel::Nodes::NotIn.new(self, sanitize_relation(rel))
        elsif rel.is_a?(Array) && rel.include?(nil)
          rel = rel.compact
          rel.empty? ? self.not_eq(nil) : self.not_in(rel).and(self.not_eq(nil))
        else
          super
        end
      end

      def _arel
        if @parent.kind_of?(BabySqueel::Association) && !@parent.alias?
          @parent.find_alias[@name]
        else
          super
        end
      end

      private

      # NullRelation must be treated as a special case, because
      # NullRelation#to_sql returns an empty string. As such,
      # we need to convert the NullRelation to regular relation.
      # Conveniently, this approach automatically adds a 1=0.
      # I have literally no idea why, but I'll take it.
      def sanitize_relation(rel)
        if rel.kind_of? ::ActiveRecord::NullRelation
          other = rel.spawn
          other.extending_values -= [::ActiveRecord::NullRelation]
          sanitize_relation rel.unscoped.merge(other)
        else
          rel = rel.spawn.select(rel.klass.primary_key) if rel.select_values.empty?
          Arel.sql rel.to_sql
        end
      end
    end
  end
end
