class BaseController < JSONAPI::ResourceController
  include JSONAPI::Utils
  protect_from_forgery with: :null_session
  rescue_from ActiveRecord::RecordNotFound, with: :jsonapi_render_not_found
end

class PostsController < BaseController
  # GET /users/:user_id/posts
  def index
    @posts = User.find(params[:user_id]).posts
    jsonapi_render json: @posts
  end

  # GET /posts/:id
  def show
    @post = Post.find(params[:id])
    jsonapi_render json: @post
  end
end

class UsersController < BaseController
  # GET /users
  def index
    @users = User.all
    jsonapi_render json: @users
  end

  # GET /users/:id
  def show
    @user = User.find(params[:id])
    jsonapi_render json: @user
  end

  # GET /no_json_key_failure
  def no_json_key_failure
    jsonapi_render foo: :bar
  end
end
