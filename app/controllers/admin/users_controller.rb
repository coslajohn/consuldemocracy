class Admin::UsersController < Admin::BaseController
  load_and_authorize_resource

  has_filters %w[active erased], only: :index

  def index
    @users = @users.send(@current_filter)
    @users = @users.by_username_email_or_document_number(params[:search]) if params[:search]
    @users = @users.page(params[:page])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path(search: @user.email), notice: t("admin.users.update.notice")
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(segment_ids: [])
  end
end
