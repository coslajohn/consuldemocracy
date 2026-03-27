class Polls::FormComponent < ApplicationComponent
  attr_reader :web_vote
  delegate :poll, :questions, to: :web_vote

  def initialize(web_vote)
    @web_vote = web_vote
  end

  private

    def form_attributes
      { url: answer_poll_path(poll), method: :post, html: { class: "poll-form" }}
    end

    def disabled?
      # Extract the user straight from the WebVote object!
      voter = web_vote.user || User.new(guest: true)

      !poll.answerable_by?(voter) || (voter.persisted? && poll.voted_in_booth?(voter))
    end
end
