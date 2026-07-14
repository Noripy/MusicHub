class TrackEntriesController < ApplicationController
  before_action :set_event, except: :index

  # 全イベント横断で自分の未識別エントリのみを新しい順に表示する（機能⑫）。
  def index
    @track_entries = Current.user.track_entries.unidentified.includes(:event).order(created_at: :desc)
  end

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

  def edit
    @track_entry = @event.track_entries.find(params[:id])
  end

  def update
    @track_entry = @event.track_entries.find(params[:id])
    if @track_entry.update(track_entry_params)
      redirect_to event_path(@event), notice: "楽曲を更新しました"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @track_entry = @event.track_entries.find(params[:id])
    @track_entry.destroy
    redirect_to event_path(@event), notice: "楽曲を削除しました"
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
