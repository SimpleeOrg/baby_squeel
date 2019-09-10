require 'spec_helper'
require 'baby_squeel/operators'

describe BabySqueel::Operators::Grouping do
  let(:proxy) {
    Class.new(BabySqueel::Nodes::Proxy) {
      include BabySqueel::Operators::Grouping
    }
  }

  let(:attribute) {
    proxy.new(Post.arel_table[:id])
  }

  describe '#&' do
    let(:sql) { '"posts"."id" IS NOT NULL AND "posts"."id" != 1' }
    subject   { attribute.not_eq(nil) & attribute.not_eq(1) }
    specify   { is_expected.to produce_sql sql }
  end

  describe '#|' do
    let(:sql) { '("posts"."id" IS NULL OR "posts"."id" = 1)' }
    subject   { attribute.eq(nil) | attribute.eq(1) }
    specify   { is_expected.to produce_sql sql }
  end

  describe '#-@' do
    let(:sql) { 'NOT ("posts"."id" IS NULL)' }
    subject   { -attribute.eq(nil) }
    specify   { is_expected.to produce_sql sql }
  end
end
