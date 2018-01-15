require 'rails_helper'

describe JSONAPI::Utils::Support::Pagination do
  subject do
    OpenStruct.new(params: {}).extend(JSONAPI::Utils::Support::Pagination)
  end

  before(:all) do
    FactoryGirl.create_list(:user, 2)
  end

  let(:options) { {} }

  ##
  # Public API
  ##

  describe '#record_count_for' do
    context 'with array' do
      let(:records) { User.all.to_a }

      it 'applies memoization on the record count' do
        expect(records).to receive(:length).and_return(records.length).once
        2.times { subject.record_count_for(records, options) }
      end
    end

    context 'with ActiveRecord object' do
      let(:records) { User.all }

      it 'applies memoization on the record count' do
        expect(records).to receive(:except).and_return(records).once
        2.times { subject.record_count_for(records, options) }
      end
    end
  end

  ##
  # Private API
  ##

  describe '#count_records' do
    shared_examples_for 'counting records' do
      it 'counts records' do
        expect(subject.send(:count_records, records, options)).to eq(count)
      end
    end

    context 'with count present within the options' do
      let(:records) { User.all }
      let(:options) { { count: 999 } }
      let(:count)   { 999 }
      it_behaves_like 'counting records'
    end

    context 'with array' do
      let(:records) { User.all.to_a }
      let(:count)   { records.length }
      it_behaves_like 'counting records'
    end

    context 'with ActiveRecord object' do
      let(:records) { User.all }
      let(:count)   { records.count }
      it_behaves_like 'counting records'
    end

    context 'when no strategy can be applied' do
      let(:records) { Object.new }
      let(:count)   { }

      it 'raises an error' do
        expect {
          subject.send(:count_records, records, options)
        }.to raise_error(JSONAPI::Utils::Support::Pagination::RecordCountError)
      end
    end
  end

  describe '#count_records_from_database' do
    shared_examples_for 'skipping eager load SQL when counting records' do
      it 'skips any eager load for the SQL count query (default)' do
        expect(records).to receive(:except)
          .with(:includes, :group, :order)
          .and_return(User.all)
          .once
        expect(records).to receive(:except)
          .with(:group, :order)
          .and_return(User.all)
          .exactly(0)
          .times
        subject.send(:count_records_from_database, records, options)
      end
    end

    context 'when not eager loading records' do
      let(:records) { User.all }
      it_behaves_like 'skipping eager load SQL when counting records'
    end

    context 'when eager loading records' do
      let(:records) { User.includes(:posts) }
      it_behaves_like 'skipping eager load SQL when counting records'
    end

    context 'when eager loading records and using where clause on associations' do
      let(:records) { User.includes(:posts).where(posts: { id: 1 }) }

      it 'fallbacks to the SQL count query with eager load' do
        expect(records).to receive(:except)
          .with(:includes, :group, :order)
          .and_raise(ActiveRecord::StatementInvalid)
          .once
        expect(records).to receive(:except)
          .with(:group, :order)
          .and_return(User.all)
          .once
        subject.send(:count_records_from_database, records, options)
      end
    end
  end

  describe '#distinct_count_sql' do
    let(:records) { OpenStruct.new(table_name: 'foos', primary_key: 'id') }

    it 'builds the distinct count SQL query' do
      expect(subject.send(:distinct_count_sql, records)).to eq('DISTINCT foos.id')
    end
  end
end
