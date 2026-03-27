class PollsController < ApplicationController
  include FeatureFlags

  feature_flag :polls

  before_action :load_poll, except: [:index]
  before_action :load_active_poll, only: :index

  # 1. This runs FIRST: Creates the guest if they hit "Vote"
  prepend_before_action :ensure_guest_user!, only: [:answer]

  # 2. This runs SECOND: Assigns the user (whether logged in, newly created guest, or nil visitor)
  before_action :set_voter

  # 3. This runs THIRD: CanCanCan checks permissions using current_ability
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

    @web_vote = Poll::WebVote.new(@poll, @voter)

    if @web_vote.update(answer_params)
      if answer_params.blank?
        redirect_to @poll, notice: t("flash.actions.create.poll_voter_blank")
      else
        redirect_to @poll, notice: t("flash.actions.create.poll_voter")
      end
    else
      @comment_tree = CommentTree.new(@poll, params[:page], @current_order)
      render :show
    end
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

    def answer_params
      params[:web_vote] || {}
    end

    # Centralized identity assignment
    def set_voter
      @voter = current_or_guest_user
    end
end
