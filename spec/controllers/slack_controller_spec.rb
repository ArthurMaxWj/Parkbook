require 'rails_helper'

RSpec.describe SlackController do # TODO: use fixtures, or better, factorybot
  context "when token/sercert auth fails" do
    subject { post('api_entry') }

    it { is_expected.to have_http_status(200) }
  end

  context "when token/secret ok" do
    let (:response_ok) {
      post('api_entry', :params => (
        ENV['SLACK_USE_TOKEN_OR_SECRET'] == 'token' ? { token: ENV['SLACK_TOKEN'] } : { secret: ENV['SLACK_SECRET'] }
      ))
    }

    it 'runs correct command' do
      expect(response_ok.body).to match(/help/i)
    end
  end
end
