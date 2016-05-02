class BaseController < JSONAPI::ResourceController
  include JSONAPI::Utils
  protect_from_forgery with: :null_session
  rescue_from ActiveRecord::RecordNotFound, with: :jsonapi_render_not_found
end

class PostsController < BaseController
  # GET /users/:user_id/posts
  def index
    @posts = { data: [
      { id: 1, title: 'Lorem Ipsum' },
      { id: 2, title: 'Dolor Sit' }
    ]}
    jsonapi_render json: @posts, options: { model: Post }
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
end
