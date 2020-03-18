require "vlc"

def w
    puts "HY"
end

module Player
    @@instance = Instance.new 0, nil

    def self.instance
        @@instance
    end

    def self.change_instance(arguments_count : Int, arguments)
        @@instance = Instance.new arguments_count, arguments
    end

    class Instance
        property obj
        getter obj
        def initialize(arguments_count : Int, arguments)
            @obj = LibVlc.new_instance arguments_count, arguments
        end

        def finalize
            LibVlc.free_instance @obj
        end
    end

    class Media
        property obj
        getter obj
        def initialize(media : String, path : Bool = true)
            if path
                @obj = LibVlc.new_media_from_path Player.instance.obj, media
            else
                @obj = LibVlc.new_media_from_location Player.instance.obj, media
            end
        end

        def finalize
            LibVlc.free_media @obj
        end
    end

    class MediaList
        property obj
        getter obj
        def initialize()
            @obj = LibVlc.new_media_list Player.instance.obj
        end

        def add(media : Media) : Bool
            LibVlc.add_media_list_media(@obj, media.obj) == 0
        end

        def finalize
            LibVlc.free_media_list @obj
        end
    end

    class MediaPlayer

        property obj, mode, media
        getter obj, mode
        def initialize(mode : MediaPlayerMode = MediaPlayerMode::Multiple)
            @mode = mode
            if @mode == MediaPlayerMode::Single
                @obj = LibVlc.new_media_player Player.instance.obj
            else
                @obj = LibVlc.new_media_list_player Player.instance.obj
            end
        end

        def play
            if @mode == MediaPlayerMode::Single
                LibVlc.play_media_player @obj
            else
                LibVlc.play_media_list_player @obj
            end
        end

        def pause
            if @mode == MediaPlayerMode::Single
                LibVlc.pause_media_player @obj
            else
                LibVlc.pause_media_list_player @obj
            end
        end

        def set_media(media : Media | MediaList)
            if media.is_a?(Media)
                if @mode == MediaPlayerMode::Single
                    LibVlc.set_media_player_media @obj, media.obj
                    @media = media
                else
                    list = MediaList.new
                    list.add media
                    @media = list
                    LibVlc.set_media_list_player_media_list @obj, list.obj
                end
            else
                if @mode == MediaPlayerMode::Single
                    raise "MediaList not allowed when using MediaPlayerMode Single"
                end
                @media = media
                 LibVlc.set_media_list_player_media_list @obj, media.obj
            end
        end

        def on(event : LibVlc::Event, proc : LibVlc::Callback, user_data = nil)
            

            if event.to_i >= 0x100 && event.to_i < 0x200
                if @mode == MediaPlayerMode::Single
                    mng = LibVlc.get_media_player_event_manager @obj
                else
                    mng = LibVlc.get_media_player_event_manager LibVlc.get_media_list_player_media_player(@obj)
                end
            else
                if @mode == MediaPlayerMode::Single
                    mng = LibVlc.get_media_player_event_manager @obj
                else
                    mng = LibVlc.get_media_list_player_event_manager @obj
                end
            end
            LibVlc.attach_event(mng, event, proc, user_data)
           # end
            proc
        end

        def on(event : LibVlc::Event, user_data = nil, &block : LibVlc::EventData*, Void* -> Nil)
            on(event, block, user_data)
        end

        def off(event : LibVlc::Event, proc : LibVlc::Callback, user_data = nil)
            if event.to_i >= 0x100 && event.to_i < 0x200
                if @mode == MediaPlayerMode::Single
                    mng = LibVlc.get_media_player_event_manager @obj
                else
                    mng = LibVlc.get_media_player_event_manager LibVlc.get_media_list_player_media_player(@obj)
                end
            else
                if @mode == MediaPlayerMode::Single
                    mng = LibVlc.get_media_player_event_manager @obj
                else
                    mng = LibVlc.get_media_list_player_event_manager @obj
                end
            end
            LibVlc.detach_event(mng, event, proc, user_data)
           # end
            proc
        end

        def off(event : LibVlc::Event, user_data = nil, &block : LibVlc::EventData*, Void* -> Nil)
            off(event, block, user_data)
        end

        def once(event : LibVlc::Event, proc : LibVlc::Callback, user_data = nil)
            on(event, LibVlc::Callback.new { |a,b|
                Pointer(LibVlc::Callback).new(b.address).value.call(a, Pointer(Void).null)
            }, pointerof(proc))   
        end

        def finalize
            if @mode == MediaPlayerMode::Single
                LibVlc.free_media_player @obj
            else
                LibVlc.free_media_list_player @obj
            end
        end
    end

    enum MediaPlayerMode
        Single
        Multiple
    end

end
