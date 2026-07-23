class DebatesController < ApplicationController
  include FeatureFlags
  include CommentableActions
  include FlagActions
  include Translatable

  before_action :authenticate_user!, except: [:index, :show]
  before_action :debates_recommendations, only: :index, if: :current_user

  feature_flag :debates

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders ->(c) { Debate.debates_orders(c.current_user) }, only: :index
  has_orders %w[most_voted newest oldest], only: :show

  load_and_authorize_resource

  before_action :apply_segment_visibility, only: :index

  helper_method :resource_model, :resource_name
  respond_to :html, :js

  def index
    # 1. Force our segment scope and apply Kaminari pagination
    user_segment_ids = current_user&.segment_ids || []

    @debates = @debates.public_or_for_user_segments(user_segment_ids)
                       .page(params[:page])

    # 2. Tell Consul to build the Tag Cloud using our secure collection
    @tag_cloud = TagCloud.new(resource_model, params[:search])
  end

  def create
    @debate = Debate.new(debate_params)
    @debate.author = current_user

    if @debate.save
      redirect_to debate_path(@debate), notice: t("flash.actions.create.debate")
    else
      render :new
    end
  end

  def index_customization
    @featured_debates = @debates.featured
  end

  def show
    super
    redirect_to debate_path(@debate), status: :moved_permanently if request.path != debate_path(@debate)
  end

  def unmark_featured
    @debate.update!(featured_at: nil)
    redirect_to debates_path
  end

  def mark_featured
    @debate.update!(featured_at: Time.current)
    redirect_to debates_path
  end

  def disable_recommendations
    if current_user.update(recommended_debates: false)
      redirect_to debates_path, notice: t("debates.index.recommendations.actions.success")
    else
      redirect_to debates_path, error: t("debates.index.recommendations.actions.error")
    end
  end

  private

    def debate_params
      params.require(:debate).permit(allowed_params)
    end

    def allowed_params
      [:tag_list, :terms_of_service, :related_sdg_list, translation_params(Debate)]
    end

    def resource_model
      Debate
    end

  def apply_segment_visibility
    user_segment_ids = current_user&.segment_ids || []
    @debates = @debates.public_or_for_user_segments(user_segment_ids)
  end

  def debates_recommendations
    if Setting["feature.user.recommendations_on_debates"] && current_user&.recommended_debates
      user_segment_ids = current_user.segment_ids

      @recommended_debates = Debate.public_or_for_user_segments(user_segment_ids)
                                   .recommendations(current_user)
                                   .sort_by_random
                                   .limit(3)
    end
  end
end
