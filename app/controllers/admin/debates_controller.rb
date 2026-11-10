class Admin::DebatesController < Admin::BaseController
  include FeatureFlags
  include HasOrders
  include Search

  load_and_authorize_resource

  feature_flag :debates

  has_orders %w[created_at]

  def index
    @debates = Debate.for_render
    @debates = @debates.search(@search_terms) if @search_terms.present?
    @debates = @debates.send("sort_by_#{@current_order}")

    respond_to do |format|
      format.html { @debates = @debates.page(params[:page]) }
      format.csv do
        send_data Debate::Exporter.new(@debates).to_csv,
                  filename: "debates.csv"
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    if @debate.update(debate_params)
      redirect_to admin_debates_path, notice: t("admin.debates.update.notice")
    else
      render :edit
    end
  end

  private

  def debate_params
    params.require(:debate).permit(segment_ids: [])
  end
end
