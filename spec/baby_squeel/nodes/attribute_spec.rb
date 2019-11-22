require 'spec_helper'
require 'baby_squeel/nodes'
require 'baby_squeel/table'

describe BabySqueel::Nodes::Attribute do
  subject(:attribute) {
    described_class.new(
      create_relation(Post),
      :id
    )
  }

  describe '#in' do
    it 'doesnt break existing in behavior' do
      expect(attribute.in([1, 2])).to produce_sql('"posts"."id" IN (1, 2)')
    end

    it 'accepts an ActiveRecord relation' do
      relation = Post.selecting { id }.where.has { title == nil }

      expect(attribute.in(relation)).to produce_sql(<<-EOSQL)
        "posts"."id" IN (
          SELECT "posts"."id"
          FROM "posts"
          WHERE "posts"."title" IS NULL
        )
      EOSQL
    end

    it 'accepts an ActiveRecord relation with limit' do
      relation = Post.selecting { id }.limit(3)

      expect(attribute.in(relation)).to produce_sql(<<-EOSQL)
        "posts"."id" IN (SELECT "posts"."id" FROM "posts" LIMIT 3)
      EOSQL
    end

    it 'accepts an ActiveRecord relation without any selected values and uses the primary_key as selected value' do
      relation = Post.all

      expect(attribute.in(relation)).to produce_sql(<<-EOSQL)
        "posts"."id" IN (SELECT "posts"."id" FROM "posts")
      EOSQL
    end

    it 'handles array containing only nils correctly' do
      expect(attribute.in([nil, nil])).to produce_sql('"posts"."id" IS NULL')
    end

    it 'handles array containing nils and other values correctly' do
      expect(attribute.in([1, nil, nil])).to produce_sql('("posts"."id" IN (1) OR "posts"."id" IS NULL)')
    end

    it 'handles nested arrays' do
      expect(attribute.in([1, [2,3]])).to produce_sql('"posts"."id" IN (1, 2, 3)')
    end

    it 'returns a BabySqueel node' do
      relation = Post.select(:id)
      expect(attribute.in(relation)).to respond_to(:_arel)
    end
  end

  describe '#not_in' do
    it 'doesnt break existing not_in behavior' do
      expect(attribute.not_in([1, 2])).to produce_sql('"posts"."id" NOT IN (1, 2)')
    end

    it 'accepts an ActiveRecord relation' do
      relation = Post.selecting { id }.where.has { title == nil }

      expect(attribute.not_in(relation)).to produce_sql(<<-EOSQL)
        "posts"."id" NOT IN (
          SELECT "posts"."id"
          FROM "posts"
          WHERE "posts"."title" IS NULL
        )
      EOSQL
    end

    it 'accepts an ActiveRecord relation with limit' do
      relation = Post.selecting { id }.limit(3)

      expect(attribute.not_in(relation)).to produce_sql(<<-EOSQL)
        "posts"."id" NOT IN (SELECT "posts"."id" FROM "posts" LIMIT 3)
      EOSQL
    end

    it 'accepts an ActiveRecord relation without any selected values and uses the primary_key as selected value' do
      relation = Post.all

      expect(attribute.not_in(relation)).to produce_sql(<<-EOSQL)
        "posts"."id" NOT IN (SELECT "posts"."id" FROM "posts")
      EOSQL
    end

    it 'handles array containing only nils correctly' do
      expect(attribute.not_in([nil, nil])).to produce_sql('"posts"."id" IS NOT NULL')
    end

    it 'handles array containing nils and other values correctly' do
      expect(attribute.not_in([1, nil, nil])).to produce_sql('"posts"."id" NOT IN (1) AND "posts"."id" IS NOT NULL')
    end

    it 'handles nested arrays' do
      expect(attribute.not_in([1, [2,3]])).to produce_sql('"posts"."id" NOT IN (1, 2, 3)')
    end
  end
end
