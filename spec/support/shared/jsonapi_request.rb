require 'spec_helper'

##
# JSON API's top-level nodes
##

shared_examples_for 'base top-level nodes' do |options|
  it 'has the "data" node' do
    expect(data).to be_present
  end

  it 'has the "id" node' do
    all = data.all? { |e| e['id'].present? }
    expect(all).to be_truthy
  end

  it 'has the "attributes" node' do
    all = data.all? { |e| e['attributes'].present? }
    expect(all).to be_truthy
  end

  it "returns a collection of #{options[:resource]}" do
    all = data.all? { |e| e['type'] == options[:resource].to_s }
    expect(all).to be_truthy
  end
end

##
# Query string params
##

shared_examples_for 'fields' do |fields|
  it 'returns only the listed fields' do
    Array(fields).each do |field|
      expect(data[0]['attributes'][field.to_s]).to be_present
    end
  end
end

shared_examples_for 'include' do |nested_resources|
  Array(nested_resources).each do |resource|
    unless resource.is_a?(Hash)
      resource = { name: resource, type: resource }
    end

    context resource[:name].to_s do
      it %Q{includes at the "include" node} do
        type = resource[:type].to_s.pluralize
        any = json['included'].any? { |e| e['type'] == type }
        expect(any).to be_truthy
      end

      it 'includes the "self" and "related" links in "relationships"' do
        links = data[0]['relationships'][resource[:name].to_s]['links']
        expect(links['self']).to be_present
        expect(links['related']).to be_present
      end
    end
  end
end

shared_examples_for 'page' do |options|
  it 'returns the paginated results' do
    expect(data.size).to be <= options[:size]
  end

  it 'includes "record_count" in "meta"' do
    record_count = json['meta']['record_count']
    expect(record_count).to be >= options[:count].to_i
  end

  it 'includes pagination links' do
    expect(json['links']['first']).to be_present
    expect(json['links']['last']).to be_present
  end
end

shared_examples_for 'first page' do
  context %q{when it's the first page} do
    it 'includes the "next" node' do
      expect(json['links']['next']).to be_present
    end

    it 'does not include the "prev" node' do
      expect(json['links']['prev']).not_to be_present
    end
  end
end

shared_examples_for 'middle page' do
  context %q{when it's not the first neither the last page} do
    it 'includes the "next" node' do
      expect(json['links']['next']).to be_present
    end

    it 'includes the "prev" node' do
      expect(json['links']['prev']).to be_present
    end
  end
end

shared_examples_for 'beyond the last page' do
  context %q{when pagination ends} do
    it 'does not include the "next" node' do
      expect(json['links']['next']).not_to be_present
    end

    it 'includes the "prev" node' do
      expect(json['links']['prev']).to be_present
    end
  end
end
