RSpec.describe Pronto::Blacklist do
  let(:blacklist) { described_class.new(patches) }
  let(:patches) { nil }

  describe '#run' do
    context 'patches are nil' do
      let(:patches) { nil }

      it 'returns an empty array' do
        expect(blacklist.run).to eq([])
      end
    end

    context 'no patches' do
      let(:patches) { [] }

      it 'returns an empty array' do
        expect(blacklist.run).to eq([])
      end
    end
  end
end
