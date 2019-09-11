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
