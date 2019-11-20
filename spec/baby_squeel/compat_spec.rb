require 'spec_helper'

describe 'BabySqueel::Compat::DSL', :compat do
  subject(:dsl) { create_dsl Post }

  describe '#`' do
    it 'creates a SQL literal' do
      expect(
        dsl.evaluate { `hello` }
      ).to be_an(Arel::Nodes::SqlLiteral)
    end
  end

  describe '#my' do
    it 'calls back to the original binding' do
      @something = 'test'

      values = dsl.evaluate do
        [@something, my { @something }]
      end

      expect(values).to eq([nil, 'test'])
    end
  end

  describe '#evaluate' do
    it 'resolves polymorphic associations using shorthand syntax' do
      resolution = nil
      dsl.evaluate { resolution = pictures.imageable(Post) }
      expect(resolution).to be_a(BabySqueel::Association)
      expect(resolution._scope).to eq(Post)
      expect(resolution._table).to eq(Post.arel_table)
      expect(resolution._polymorphic_klass).to eq(Post)
    end

    if ActiveRecord::VERSION::MAJOR < 5
      describe 'association comparison' do
        let(:an_author) { Author.create!(name: 'George Martin') }
        let(:a_post) { Post.create!(title: 'A Song of Ice and Fire', author: an_author) }

        it 'generates the correct SQL for regular associations' do
          expect(dsl.evaluate { author == my{an_author} }).to produce_sql("\"posts\".\"author_id\" = #{an_author.id}")
          expect(dsl.evaluate { author != my{an_author} }).to produce_sql("NOT (\"posts\".\"author_id\" = #{an_author.id})")
          expect(dsl.evaluate { author == nil }).to produce_sql('"posts"."author_id" IS NULL')
        end

        it 'generates the correct SQL for polymorphic associations' do
          expect(dsl.evaluate { pictures.imageable == my{a_post} }).to produce_sql("\"pictures\".\"imageable_id\" = #{a_post.id} AND \"pictures\".\"imageable_type\" = 'Post'")
          expect(dsl.evaluate { pictures.imageable != my{a_post} }).to produce_sql("NOT (\"pictures\".\"imageable_id\" = #{a_post.id} AND \"pictures\".\"imageable_type\" = 'Post')")
          expect(dsl.evaluate { pictures.imageable == nil }).to produce_sql('"pictures"."imageable_id" IS NULL')
        end

        it 'throws an error for invalid comparisons' do
          expect {
            dsl.evaluate { author == 'bazinga' }
          }.to raise_error(BabySqueel::AssociationComparisonError)
          expect {
            dsl.evaluate { author != 0 }
          }.to raise_error(BabySqueel::AssociationComparisonError)
        end
      end
    end

    it 'resolves boolean values' do
      expect(dsl.evaluate { true }).to produce_sql('1')
      expect(dsl.evaluate { false }).to produce_sql('0')
    end
  end
end

describe 'BabySqueel::Compat::QueryMethods', :compat do
  describe '#includes' do
    it 'accepts a block' do
      posts = Post.includes { author.posts }
      expect(posts.includes_values).to eq([ author: { posts: {} } ])
    end

    it 'handles arrays' do
      posts = Post.includes { [comments, author.posts] }
      expect(posts.includes_values).to eq([ { comments: {} }, author: { posts: {} } ])
    end

    it 'handles nil' do
      posts = Post.includes { nil }
      expect(posts.includes_values).to eq([])
    end
  end

  describe '#eager_load' do
    it 'accepts a block' do
      posts = Post.eager_load { author.posts }
      expect(posts.eager_load_values).to eq([ author: { posts: {} } ])
    end
  end

  describe '#preload' do
    it 'accepts a block' do
      posts = Post.preload { author.posts }
      expect(posts.preload_values).to eq([ author: { posts: {} } ])
    end
  end
end
