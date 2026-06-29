class EventsController < ApplicationController
  def index
    @events = Current.user.events.order(held_on: :desc, created_at: :desc)
  end

  def show
    @event = Current.user.events.includes(:track_entries).find(params[:id])
    @track_entries = @event.track_entries.order(created_at: :asc)
  end

  def new
    @event = Current.user.events.build
  end

  def create
    @event = Current.user.events.build(event_params)
    if @event.save
      redirect_to events_path, notice: "イベントを登録しました"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

    def event_params
      params.require(:event).permit(:name, :held_on, :venue, :dj_name)
    end
end
