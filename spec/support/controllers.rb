require 'support/exceptions'

class BaseController < JSONAPI::ResourceController
  include JSONAPI::Utils
  protect_from_forgery with: :null_session
  rescue_from ActiveRecord::RecordNotFound, with: :jsonapi_render_not_found
end

class PostsController < BaseController
  before_action :load_user, except: %i(index_with_hash show_with_hash)

  # GET /users/:user_id/posts
  def index
    jsonapi_render json: @user.posts, options: { count: 100 }
  end

  # GET /index_with_hash
  def index_with_hash
    @posts = { data: [
      { id: 1, title: 'Lorem Ipsum' },
      { id: 2, title: 'Dolor Sit' }
    ]}
    jsonapi_render json: @posts, options: { model: Post }
  end

  # GET /users/:user_id/posts/:id
  def show
    jsonapi_render json: @user.posts.find(params[:id])
  end

  # GET /show_with_hash/:id
  def show_with_hash
    jsonapi_render json: { data: { id: params[:id], title: 'Lorem ipsum' } },
                   options: { model: Post, resource: ::V2::PostResource }
  end

  # POST /users/:user_id/posts
  def create
    new_post = FactoryGirl.create(:post, user: @user)
    jsonapi_render json: new_post, status: :created
  end

  protected

  def load_user
    @user = User.find(params[:user_id])
  end
end

class UsersController < BaseController
  # GET /users
  def index
    users = User.all
    jsonapi_render json: users
  end

  # GET /users/:id
  def show
    user = User.find(params[:id])
    jsonapi_render json: user
  end

  # POST /users
  def create
    user = User.new(user_params)
    if user.save
      jsonapi_render json: user, status: :created
    else
      jsonapi_render_errors ::Exceptions::ActiveRecordError.new(user)
    end
  end

  protected

  def user_params
    params.require(:data).require(:attributes).permit(:first_name, :last_name, :admin)
  end
end
