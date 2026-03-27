class PollsController < ApplicationController
  include FeatureFlags

  feature_flag :polls

  before_action :load_poll, except: [:index]
  before_action :load_active_poll, only: :index

  # Ensure a guest user exists in the session before allowing an answer
  prepend_before_action :ensure_guest_user!, only: [:answer, :guest_verification]

  before_action :set_voter

  load_and_authorize_resource

  has_filters %w[current expired]
  has_orders %w[most_voted newest oldest], only: [:show, :answer]

  def index
    @polls = Kaminari.paginate_array(
      @polls.created_by_admin.not_budget.send(@current_filter).includes(:geozones).sort_for_list(@voter)
    ).page(params[:page])
  end

  def show
    @web_vote = Poll::WebVote.new(@poll, @voter)
    @comment_tree = CommentTree.new(@poll, params[:page], @current_order)
  end

  def answer
    raise CanCan::AccessDenied if @poll.voted_in_booth?(@voter)
    puts "DEBUG PARAMS: #{params.inspect}"
    # 1. THE REDIRECT TRIGGER
    # If a guest tries to vote but hasn't "signed" yet, and isn't currently submitting the ID form
    if @voter.guest? && @voter.document_number.blank? && !guest_identity_params_present?
      session[:pending_vote] = {
        poll_id: @poll.id,
        web_vote: params[:web_vote]
      }
      redirect_to guest_verification_poll_path(@poll) and return
    end

    # If they are a guest and just submitted the identity fields from the verification page
    if @voter.guest? && guest_identity_params_present?
      # This method maps initials/postcode/year to document_number and date_of_birth
      unless @voter.finalize_guest_identity(params)
        flash.now[:error] = @voter.errors.full_messages.join(", ")
        render :guest_verification and return
      end
      @voter.reload
    end

    vote_data = params[:web_vote] || session.delete(:pending_vote)&.dig("web_vote")

    @web_vote = Poll::WebVote.new(@poll, @voter)

    begin
      if @web_vote.update(vote_data)

        reset_session

        redirect_to polls_path, notice: t("flash.actions.create.poll_voter")
      else
        # Standard "update returned false" handling
        render_error_page
      end
    rescue ActiveRecord::RecordInvalid => e
      # This catches the "This identity has already cast a vote" crash
      flash.now[:error] = e.record.errors.full_messages.first

      if @voter.guest?
        render :guest_verification
      else
        @comment_tree = CommentTree.new(@poll, params[:page], @current_order)
        render :show
      end
    end
  end

  def guest_verification
    # Ensure there is a pending vote in the session for THIS poll
    pending = session[:pending_vote]
    if pending.blank? || pending["poll_id"].to_i != @poll.id
      redirect_to @poll, alert: t("polls.guest_verification.no_pending_vote") and return
    end

    @web_vote = Poll::WebVote.new(@poll, @voter)
    # This view will show the form for Initials, Postcode, and Year of Birth
  end

  def stats
    @stats = Poll::Stats.new(@poll).tap(&:generate)
  end

  def results
  end

  private

    def load_poll
      @poll = Poll.find_by_slug_or_id!(params[:id])
    end

    def load_active_poll
      @active_poll = ActivePoll.first
    end

    def set_voter
      @voter = current_or_guest_user
    end

    def guest_identity_params_present?
      params[:guest_initials].present? &&
        params[:guest_postal_code].present? &&
        params[:guest_year_of_birth].present?
    end

    # This ensures the strong params for WebVote are handled
    def answer_params
      params[:web_vote] || {}
    end
    def render_error_page
      if @voter.guest?
        render :guest_verification
      else
        @comment_tree = CommentTree.new(@poll, params[:page], @current_order)
        render :show
      end
    end
end
