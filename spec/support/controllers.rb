class BaseController < JSONAPI::ResourceController
  include JSONAPI::Utils
  protect_from_forgery with: :null_session
  rescue_from ActiveRecord::RecordNotFound, with: :jsonapi_render_not_found_with_null
end

class PostsController < BaseController
  # GET /users/:id/posts
  def index
    @posts = User.find(param[:id]).posts
    jsonapi_render json: @posts, options: { count: @posts.count }
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
    jsonapi_render json: @users, options: { count: @users.count }
  end

  # GET /users/:id
  def show
    @user = User.find(params[:id])
    jsonapi_render json: @user
  end
end
