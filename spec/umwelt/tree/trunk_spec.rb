# frozen_string_literal: true

require_relative '../../spec_helper'

describe Umwelt::Tree::Trunk do
  subject do
    Umwelt::Tree::Fill.new.call [root, parent, uncle, member]
  end

  let(:root) { Fabricate.build(:root, body: 'Project_root', kind: 'root') }
  let(:parent) { Fabricate.build(:parent, kind: 'space') }
  let(:uncle) { Fabricate.build(:uncle, kind: 'space') }
  let(:member) { Fabricate.build(:member, kind: 'space') }

  describe '#nodes' do
    it 'returnes modes array' do
      _(subject.nodes).must_equal [
        subject.node(root.id),
        subject.node(parent.id),
        subject.node(uncle.id),
        subject.node(member.id)
      ]
    end
  end

  describe '#node(id)' do
    let(:node) { subject.node(member.id) }
    it 'returnes node' do
      _(node).must_be_kind_of Umwelt::Node::Base
    end

    it 'is a node' do
      _(node).must_be_instance_of Umwelt::Node::Space
    end
  end

  describe '#childs(id)' do
    let(:childs) { subject.childs(root.id) }
    it 'returnes node' do
      _(childs).must_be_kind_of Array
    end

    it 'includes childs nodes' do
      _(childs).must_include subject.node(parent.id)
      _(childs).must_include subject.node(uncle.id)
    end
  end
end
