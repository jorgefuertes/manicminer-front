ManicminerPool::App.controllers :news do


	get '/:slug' do
		@post = Post.first(:slug => params[:slug])
		halt 404, 'Post not found' unless @post
		render 'home/news-single'
	end

	get '/' do
		render 'home/news'
	end

end
