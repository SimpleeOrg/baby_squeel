require 'spec_helper'
require 'baby_squeel/association'
require 'shared_examples/table'

describe BabySqueel::Association do
  subject(:association) { create_association Author, :posts }
  let(:polymorph) { create_association Picture, :imageable }

  it_behaves_like 'a table' do
    let(:table) { association }
  end

  describe '#of' do
    specify { expect(polymorph._scope).to be_nil }
    specify { expect(polymorph._table).to be_nil }
    specify { expect(polymorph._polymorphic_klass).to be_nil }

    it 'assigns the _scope' do
      expect(polymorph.of(Post)._scope).to eq(Post)
    end

    it 'assigns the _table' do
      expect(polymorph.of(Post)._table).to eq(Post.arel_table)
    end

    it 'assigns the _polymorphic_klass' do
      expect(polymorph.of(Post)._polymorphic_klass).to eq(Post)
    end

    it 'throws a fit when the reflection is not polymorphic' do
      expect{ association.of(Post) }.to raise_error(BabySqueel::PolymorphicSpecificationError)
    end
  end

  describe '#==' do
    subject(:association) { create_association Post, :author }

    if ActiveRecord::VERSION::MAJOR >= 5
      it 'generates SQL' do
        node = association == Author.new(id: 42)
        expect(node._arel.to_sql).to match_sql_snapshot(variants: ['5.2'])
      end

      it 'throws for an invalid comparison' do
        expect {
          association == 'foo'
        }.to raise_error(BabySqueel::AssociationComparisonError)
      end
    else
      it 'throws not supported' do
        if ENV['COMPAT']
          skip "This isn't supported in Squeel Compatibility mode"
        end
        expect {
          association == 'foo'
        }.to raise_error(BabySqueel::AssociationComparisonNotSupportedError)
      end
    end
  end

  describe '#!=' do
    subject(:association) { create_association Post, :author }

    if ActiveRecord::VERSION::MAJOR >= 5
      it 'generates SQL' do
        node = association != Author.new(id: 42)
        expect(node._arel.to_sql).to match_sql_snapshot(variants: ['5.2'])
      end

      it 'throws for an invalid comparison' do
        expect {
          association != 'foo'
        }.to raise_error(BabySqueel::AssociationComparisonError)
      end
    else
      it 'throws not supported' do
        if ENV['COMPAT']
          skip "This isn't supported in Squeel Compatibility mode"
        end
        expect {
          association != 'foo'
        }.to raise_error(BabySqueel::AssociationComparisonNotSupportedError)
      end
    end
  end

  describe '#add_to_tree' do
    def make_tree(tree_node)
      hash = {}
      tree_node.add_to_tree(hash)
      hash.keys.first
    end

    it 'builds a Polyamorous::Join' do
      join = make_tree(association)
      expect(join.name).to eq(:posts)
      expect(join.type).to eq(Arel::Nodes::InnerJoin)
      expect(join.klass).to be_nil
    end

    it 'builds a Polyamorous::Join (for outer)' do
      join = make_tree(association.outer)
      expect(join.name).to eq(:posts)
      expect(join.type).to eq(Arel::Nodes::OuterJoin)
      expect(join.klass).to be_nil
    end

    it 'includes the _polymorphic_klass for polymorphic associations' do
      join = make_tree(polymorph.of(Post))
      expect(join.name).to eq(:imageable)
      expect(join.klass).not_to be_nil
    end
  end

  describe '#method_missing' do
    it 'raises a NoMethodError when the wrong number of args are given' do
      expect { association.author(1) }.to raise_error(NoMethodError)
    end
  end

  describe '#_arel' do
    context 'when explicitly joining' do
      let(:condition) { association.author_id == association.author.id }
      let(:assoc)     { association.author.on(condition) }

      it 'resolves to an Arel join node' do
        expect(assoc._arel).to be_an(Arel::Nodes::InnerJoin)
      end

      it 'sets an on clause on the Join' do
        expect(assoc._on).not_to be_nil
      end

      it 'lets you alias' do
        expect(assoc.alias('fun')._arel.left).to be_an(Arel::Nodes::TableAlias)
      end
    end

    context 'when implicitly joining' do
      context 'when inner joining' do
        it 'resolves to a hash' do
          expect(association._arel).to eq(posts: {})
        end

        it 'throws a fit when an alias is attempted' do
          expect {
            association.alias('naughty')._arel
          }.to raise_error(BabySqueel::AssociationAliasingError)
        end
      end

      context 'when outer joining' do
        it 'resolves to a Join' do
          expect(association.outer._arel).to be_a(BabySqueel::Join)
        end

        it 'throws a fit when an alias is attempted' do
          expect {
            association.alias('naughty')._arel
          }.to raise_error(BabySqueel::AssociationAliasingError)
        end
      end

      context 'when joining polymorphic associations' do
        it 'throws an error if the _polymorphic_klass has not been set' do
          expect { polymorph._arel }.to raise_error(BabySqueel::PolymorphicNotSpecifiedError)
        end
      end
    end
  end

  describe '#find_alias' do
    it 'finds the alias' do
      expect(association.find_alias.name).to eq('posts')
    end

    # Without `reconstruct_with_type_caster`, this would fail in Active Record 5.
    # See: https://github.com/rails/rails/pull/27994
    it 'uses the correct type_caster' do
      view_count = association.find_alias[:view_count]
      expect(view_count.eq('5')).to produce_sql('"posts"."view_count" = 5')
    end
  end
end
