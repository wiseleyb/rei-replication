# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReplSqlServer, type: :service do
  describe '#check' do
    before do
      ReplUtils.create_replication_slot!
      expect(ReplUtils.replication_slot_exists?).to be_truthy
    end

    context 'running server' do
      let(:user) { create(:user) }

      before do
        expect(User).to receive(:handle_koyo_replication)
      end

      context 'without ReplRedisServer' do
        before do
          allow(ReplConfig).to receive(:use_redis?).and_return(false)
        end

        it 'works' do
          user.save!
          ReplSqlServer.new.check
        end
      end

      context 'with ReplRedisServer' do
        before do
          allow(ReplConfig).to receive(:use_redis?).and_return(true)
        end

        it 'works' do
          #expect(User).to receive(:handle_koyo_replication)
          ReplRedis.flushdb
          user.save!
          ReplSqlServer.new.check
          data = ReplUtils.parse_json(ReplRedis.rpop(ReplConfig.redis_queue))
          expect(data['kind']).to eq('insert')
          expect(data['table']).to eq('users')
        end
      end
    end

    context 'finds models to be notified' do
      let(:tables) { ReplSqlServer.tables_that_handle_koyo_replication }

      it 'works' do
        res = { 'users' => 'User' }
        expect(tables).to eq(res)
        expect(ReplSqlServer.new.tables).to eq(res)
      end
    end
  end
end
