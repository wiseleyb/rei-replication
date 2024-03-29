# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Koyo::Repl::PostgresServer, type: :service do
  describe '#check' do
    before do
      expect(Koyo::Repl::Database.replication_slot_exists?).to be_truthy
    end

    context 'running server' do
      let(:user) { create(:user) }

      before do
        expect(User).to receive(:handle_replication)
        expect(KoyoReplHandlerService).to receive(:koyo_handle_all_replication)
      end

      it 'works' do
        user.save!
        Koyo::Repl::PostgresServer.new.check
      end
    end

    context 'finds models to be notified' do
      let(:tables) { Koyo::Repl::PostgresServer.tables_that_handle_koyo_replication }

      it 'works' do
        res = { 'users' => 'User' }
        expect(tables).to eq(res)
        expect(Koyo::Repl::PostgresServer.new.tables).to eq(res)
      end
    end
  end
end
