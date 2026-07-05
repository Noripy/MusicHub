class TrackEntriesController < ApplicationController
  before_action :set_event

  def new
    @track_entry = @event.track_entries.build
  end

  def create
    @track_entry = @event.track_entries.build(track_entry_params)
    if @track_entry.save
      redirect_to event_path(@event), notice: "楽曲を登録しました"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

    # ログイン中ユーザーのイベントに限定。他人のイベントは RecordNotFound。
    def set_event
      @event = Current.user.events.find(params[:event_id])
    end

    def track_entry_params
      params.require(:track_entry).permit(:title, :bpm, :memo, genre: [], mood: [])
    end
end
