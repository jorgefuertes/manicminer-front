ManicminerPool::Admin.controllers :workers do
  get :index do
    @title = "Workers"
    @workers = Worker.sort(:name.asc).paginate(:page => params[:page], :per_page => 100)

    render 'workers/index'
  end

  get :new do
    @title = pat(:new_title, :model => 'worker')
    @worker = Worker.new
    render 'workers/new'
  end

  post :create do
    @worker = Worker.new(params[:worker])
    if @worker.save
      @title = pat(:create_title, :model => "worker #{@worker.id}")
      flash[:success] = pat(:create_success, :model => 'Worker')
      params[:save_and_continue] ? redirect(url(:workers, :index)) : redirect(url(:workers, :edit, :id => @worker.id))
    else
      @title = pat(:create_title, :model => 'worker')
      flash.now[:error] = pat(:create_error, :model => 'worker')
      render 'workers/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "worker #{params[:id]}")
    @worker = Worker.find(params[:id])
    if @worker
      render 'workers/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'worker', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "worker #{params[:id]}")
    @worker = Worker.find(params[:id])
    if @worker
      if @worker.update_attributes(params[:worker])
        flash[:success] = pat(:update_success, :model => 'Worker', :id =>  "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:workers, :index)) :
          redirect(url(:workers, :edit, :id => @worker.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'worker')
        render 'workers/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'worker', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy, :with => :id do
    @title = "Workers"
    worker = Worker.find(params[:id])
    if worker
      if worker.destroy
        flash[:success] = pat(:delete_success, :model => 'Worker', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'worker')
      end
      redirect url(:workers, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'worker', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    @title = "Workers"
    unless params[:worker_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'worker')
      redirect(url(:workers, :index))
    end
    ids = params[:worker_ids].split(',').map(&:strip)
    workers = Worker.find(ids)

    if workers.each(&:destroy)

      flash[:success] = pat(:destroy_many_success, :model => 'Workers', :ids => "#{ids.to_sentence}")
    end
    redirect url(:workers, :index)
  end
end
