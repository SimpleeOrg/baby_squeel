require 'spec_helper'
require 'baby_squeel/nodes'
require 'baby_squeel/operators'

describe BabySqueel::Operators::Comparison do
  let(:proxy) {
    Class.new(BabySqueel::Nodes::Proxy) {
      include BabySqueel::Operators::Comparison
    }
  }

  let(:attribute) {
    proxy.new(Post.arel_table[:id])
  }

  describe '#<' do
    subject { attribute < 1 }
    specify { is_expected.to produce_sql '"posts"."id" < 1' }
  end

  describe '#>' do
    subject { attribute > 1 }
    specify { is_expected.to produce_sql '"posts"."id" > 1' }
  end

  describe '#<=' do
    subject { attribute <= 1 }
    specify { is_expected.to produce_sql '"posts"."id" <= 1' }
  end

  describe '#>=' do
    subject { attribute >= 1 }
    specify { is_expected.to produce_sql '"posts"."id" >= 1' }
  end

  describe '#>>' do
    subject { attribute >> [1, 2] }
    specify { is_expected.to produce_sql '"posts"."id" IN (1, 2)' }
  end

  describe '#<<' do
    subject { attribute << [1, 2] }
    specify { is_expected.to produce_sql '"posts"."id" NOT IN (1, 2)' }
  end

end
