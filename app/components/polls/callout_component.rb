class Polls::CalloutComponent < ApplicationComponent
  attr_reader :poll, :user

  delegate :link_to_signin, :link_to_signup, to: :helpers

  def initialize(poll, user = nil)
    @poll = poll
    @user = user
  end

  def guest_can_answer?
    voter = user || User.new(guest: true)
    poll.answerable_by?(voter)
  end

  private

    def voted_in_booth?
      user.present? && poll.voted_in_booth?(user)
    end

    def voted_in_web?
      user.present? && poll.voted_in_web?(user)
    end

    def voted_blank?
      user.present? && poll.answers.where(author: user).none?
    end

    def callout(text, html_class: "warning")
      tag.div(text, class: "callout #{html_class}")
    end

    def not_logged_in_text
      sanitize(t("polls.show.cant_answer_not_logged_in",
                 signin: link_to_signin,
                 signup: link_to_signup))
    end

    def unverified_text
      sanitize(t("polls.show.cant_answer_verify",
                 verify_link: link_to(t("polls.show.verify_link"), verification_path)))
    end

    def guest_participation_text
      sanitize(t("polls.show.participate_fully",
                  signin: link_to_signin,
                  signup: link_to_signup))
    end
end
