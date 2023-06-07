# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReplSqlServer, type: :service do
  describe '#check' do
    context 'running server' do
      let(:user) { create(:user) }

      it 'works' do
=begin
        allow(ReplConfig).to receive(:use_redis?).and_return(false)
        expect(User).to receive(:handle_koyo_replication)
        expect(ReplUtils.replication_slot_exists?).to be_truthy
        user.save!
        ReplSqlServer.new.check
=end
      end
    end

    context 'test mock-redis' do
      it 'works' do
        k, v = SecureRandom.hex(5), SecureRandom.hex(4)
        ReplRedis.set(k, v)
        expect(ReplRedis.get(k)).to eq(v)
        ReplRedis.flushdb
        expect(ReplRedis.get(k)).to be_nil
      end
    end
  end
end
