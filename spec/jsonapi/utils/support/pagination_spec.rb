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
        expect(records).to receive(:count).and_return(records.count).once
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
      let(:count)   { records.count }
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

  describe '#count_pages_for' do
    shared_examples_for 'counting pages' do
      it 'returns the correct page count' do
        allow(subject).to receive(:page_params).and_return(page_params)
        expect(subject.send(:page_count_for, record_count)).to eq(page_count)
      end
    end

    context 'with paged paginator' do
      let(:record_count) { 10 }
      let(:page_count) { 2 }
      let(:page_params) { { 'size' => 5 } }
      it_behaves_like 'counting pages'
    end

    context 'with offset paginator' do
      let(:record_count) { 10 }
      let(:page_count) { 2 }
      let(:page_params) { { 'limit' => 5 } }
      it_behaves_like 'counting pages'
    end

    context 'with 0 records'  do
      let(:record_count) { 0 }
      let(:page_count) { 0 }
      let(:page_params) { {} }
      it_behaves_like 'counting pages'
    end

    context 'with no limit param' do
      let(:record_count) { 10 }
      let(:page_count) { 1 }
      let(:page_params) { {} }
      it_behaves_like 'counting pages'
    end
  end
end

describe JSONAPI::Utils::Support::Pagination::RecordCounter::ActiveRecordCounter do
  let(:options) { {} }

  subject { described_class.new( records, options ) }
  describe '#count' do
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
        subject.send(:count)
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
        subject.send(:count)
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

describe JSONAPI::Utils::Support::Pagination::RecordCounter do

  describe '#add' do
    context 'when adding an unusable counter type' do
      it "doesn't explode" do
        expect{ described_class.add( BogusCounter ) }.to_not raise_error( )
      end
    end

    context 'when adding good counter type' do
      subject { described_class.add( StringCounter ) }
      it 'should add it' do
        expect{ subject }.to_not( raise_error )
      end
      it 'should count' do
        expect( described_class.send( :count, "lol" ) ).to eq( 3 )
      end
    end
  end
  describe "#count" do
    context "when params are present" do
      let( :params ){ { a: :b } }
      it "passes them into the counters" do
        described_class.add HashParamCounter

        expect( described_class.send( :count, {}, params, {} ) ).to eq( { a: :b } )
      end
    end
    context "when options are present" do
      let( :options ) { { a: :b } }
      it "passes them into the counters" do
        described_class.add HashOptionsCounter

        expect( described_class.send( :count, {}, {}, options ) ).to eq( { a: :b } )
      end
    end
  end
end