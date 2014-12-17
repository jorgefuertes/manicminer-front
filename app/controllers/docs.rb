ManicminerPool::App.controllers :docs do

  get '/:docname' do
  	begin
    	render "docs/#{params[:docname]}"
    rescue
    	halt 404, "Doc not found!"
    end
  end

end
