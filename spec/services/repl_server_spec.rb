# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReplServer, type: :service do
  describe '#check' do
    let(:user) { create(:user) }

    it 'works' do
      expect(ReplUser).to receive(:handle)
      expect(ReplUtils.replication_slot_exists?).to be_truthy
      user.save!
      ReplServer.check
    end
  end
end
