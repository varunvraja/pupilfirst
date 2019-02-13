require 'rails_helper'

describe TargetsController do
  include Devise::Test::ControllerHelpers

  let!(:startup) { create :startup }
  let!(:target) { create :target }
  let!(:pending_prerequisite_target) { create :target }
  let!(:completed_prerequisite_target) { create :target }

  let!(:completion_event) do
    create :timeline_event,
      target: completed_prerequisite_target,
      passed_at: 1.day.ago,
      founders: [startup.founders.first],
      latest: true
  end

  let!(:founder_target) { create :target, role: Target::ROLE_FOUNDER }

  let!(:completion_event_2) do
    create :timeline_event,
      target: founder_target,
      passed_at: 1.day.ago,
      founders: [startup.founders.first],
      latest: true
  end

  let!(:faculty) { create :faculty }
  let!(:target_feedback) { create :startup_feedback, timeline_event: completion_event_2, faculty: faculty, startup: startup }

  describe 'GET prerequisite_targets' do
    context 'founder is not signed in' do
      it 'raises not found error' do
        get :prerequisite_targets, params: { id: target.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when a founder is signed in' do
      before do
        sign_in startup.founders.first.user
      end

      context 'when target has no prerequisite targets' do
        it 'returns an empty hash' do
          get :prerequisite_targets, params: { id: target.id }
          expect(JSON.parse(response.body)).to eq({})
        end
      end

      context 'when target has prerequisite targets' do
        before do
          target.prerequisite_targets << [pending_prerequisite_target, completed_prerequisite_target]
        end
        it 'returns a hash of pending prerequisites with ids mapped to target title' do
          get :prerequisite_targets, params: { id: target.id }
          expect(JSON.parse(response.body)).to eq(pending_prerequisite_target.id.to_s => pending_prerequisite_target.title)
        end
      end
    end
  end

  # TODO: Probably remove this as we now use the 'details' action whose response includes the latest feedback
  describe 'GET startup_feedback', broken: true do
    before do
      sign_in startup.founders.first.user
    end

    context 'when target has no feedback' do
      it 'returns an empty hash' do
        get :startup_feedback, params: { id: completed_prerequisite_target.id }
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context 'when target has feedback' do
      it 'returns a hash of startup feedback with ids mapped to the feedback' do
        expected_response = { target_feedback.id.to_s => target_feedback.feedback.to_s }
        get :startup_feedback, params: { id: founder_target.id }
        expect(JSON.parse(response.body)).to eq(expected_response)
      end
    end
  end
end
