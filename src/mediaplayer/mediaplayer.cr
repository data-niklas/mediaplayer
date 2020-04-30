require "vlc"

module Player
    @@instance = Instance.new 0, nil

    alias Event = LibVlc::Event
    alias Callback = LibVlc::Callback
    alias State = LibVlc::State
    alias MediaType = LibVlc::MediaType
    alias TrackType = LibVlc::TrackType
    alias PlaybackMode = LibVlc::PlaybackMode
    alias Meta = LibVlc::Meta
    alias MediaParsedStatus = LibVlc::MediaParsedStatus
    alias PictureType = LibVlc::PictureType
    alias Role = LibVlc::Role
    alias MediaParseFlag = LibVlc::MediaParseFlag
    alias SlaveType = LibVlc::SlaveType
    alias ThumbnailSeekSpeed = LibVlc::ThumbnailSeekSpeed

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

        def ==(instance : Instance)
            @obj == instance.obj
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

        def initialize(@obj)
        end

        def url
            String.new LibVlc.get_media_resource_locator(@obj)
        end

        def get_length() : LibVlc::Time
            LibVlc.get_media_duration @obj
        end
        
        def type : LibVlc::MediaType
            LibVlc.get_media_type @obj
        end
        
        def state : LibVlc::State
            LibVlc.get_media_state @obj
        end
        
        def parsed_status : LibVlc::MediaParsedStatus
            LibVlc.get_media_parsed_status @obj
        end

        def parse(options : Player::MediaParseFlag = Player::MediaParseFlag::ParseLocal, timeout = 0)
            LibVlc.parse_media_with_options @obj, options, timeout
        end

        def stats : LibVlc::MediaStats*
            stats = LibVlc::MediaStats.new
            LibVlc.get_media_statistics(@obj,pointerof(stats))
            pointerof(stats)
        end

        def get_formatted_length(format : Time::Format = Time::Format.new("%M:%S")) : String
            format.format(Time.unix_ms(get_length()))
        end

        def get_meta(meta : LibVlc::Meta) : String
            pmeta = LibVlc.get_media_meta(@obj, meta)
            if pmeta == Pointer(UInt8).null
                ""
            else
                String.new LibVlc.get_media_meta(@obj, meta)
            end
        end

        def set_meta(meta : LibVLc::Meta, value)
            LibVlc.set_media_meta @obj, meta, value.to_unsafe
        end

        def save_meta : Bool
            LibVlc.save_media_meta
        end

        def subitems : MediaList
            MediaList.new LibVlc.get_media_subitems(@obj)
        end


        def ==(media : Media)
            @obj == media.obj
        end

        def finalize
            LibVlc.free_media @obj
        end

        #############Events#####################

        def on(event : LibVlc::Event, proc : LibVlc::Callback, user_data = nil)
    
            mng = LibVlc.get_media_event_manager @obj
            LibVlc.attach_event(mng, event, proc, user_data)
            # end
            proc
        end

        def on(event : LibVlc::Event, user_data = nil, &block : LibVlc::EventData*, Void* -> Nil)
            on(event, block, user_data)
        end

        def off(event : LibVlc::Event, proc : LibVlc::Callback, user_data = nil)
            mng = LibVlc.get_media_event_manager @obj
            LibVlc.detach_event(mng, event, proc, user_data)
            # end
            proc
        end

        def off(event : LibVlc::Event, user_data = nil, &block : LibVlc::EventData*, Void* -> Nil)
            off(event, block, user_data)
        end
    end

    class MediaList
        property obj
        getter obj
        def initialize()
            @obj = LibVlc.new_media_list Player.instance.obj
        end

        def initialize(@obj)
        end

        def ==(media_list : MediaList)
            @obj == media_list.obj
        end

        def lock()
            LibVlc.lock_media_list @obj
        end

        def unlock()
            LibVlc.unlock_media_list @obj
        end

        def readonly?()
            LibVlc.is_media_list_readonly? @obj
        end

        def [](i : Int32) : Media
            Media.new LibVlc.get_media_list_media(@obj,index)
        end

        def []=(i : Int32, media : Media) : Media
            set i, media
        end

        def get(): Media
            Media.new LibVlc.get_media_list_media(@obj)
        end

        def get(index): Media
            Media.new LibVlc.get_media_list_media(@obj,index)
        end

        def index_of(media : Media)
            LibVlc.index_of_media_list_media @obj, media.obj
        end

        def has?(media : Media)
            index_of(media) != -1
        end

        def empty?() : Bool
            count() == 0
        end

        def set(media)
            LibVlc.set_media_list_media @obj, media.obj
        end

        def set(index : Int32, media : Media)
            remove index
            insert media, index
        end


        #Add
        def <<(media : Media) : Bool
            add(media)
        end

        def add(media : Media) : Bool
            LibVlc.add_media_list_media(@obj, media.obj) == 0
        end

        def <<(media : Media, index) : Bool
            insert(media,index)
        end

        def insert(media : Media, index) : Bool
            LibVlc.insert_media_list_media(@obj, media.obj, index) == 0
        end

        def count()
            LibVlc.get_media_list_count(@obj)
        end


        def size()
            count
        end

        def each(&block)
            count.times do |i|
                yield get(i)
            end
        end

        def each_with_index(&block)
            count.times do |i|
                yield get(i), i
            end
        end

        def >>(index) : Bool
            remove(index)
        end

        def remove(index) : Bool
            LibVlc.remove_media_list_media(@obj, index) == 0
        end    
        
        def >>(media : Media) : Bool
            remove(media)
        end

        def remove(media : Media) : Bool
            index = index_of(media)
            index == -1 || remove(index)
        end




        def finalize
            LibVlc.free_media_list @obj
        end


        #############Events#####################

        def on(event : LibVlc::Event, proc : LibVlc::Callback, user_data = nil)
            
            mng = LibVlc.get_media_list_event_manager @obj
            LibVlc.attach_event(mng, event, proc, user_data)
           # end
            proc
        end

        def on(event : LibVlc::Event, user_data = nil, &block : LibVlc::EventData*, Void* -> Nil)
            on(event, block, user_data)
        end

        def off(event : LibVlc::Event, proc : LibVlc::Callback, user_data = nil)
            mng = LibVlc.get_media_list_event_manager @obj
            LibVlc.detach_event(mng, event, proc, user_data)
           # end
            proc
        end

        def off(event : LibVlc::Event, user_data = nil, &block : LibVlc::EventData*, Void* -> Nil)
            off(event, block, user_data)
        end
    end





    class MediaPlayer

        property obj, mode, media, equalizer : Equalizer
        getter obj, mode, equalizer
        @media : Nil | MediaList | Media = nil
        def initialize(media, mode : MediaPlayerMode = MediaPlayerMode::Multiple)
            initialize(mode)
            set media
        end

        def initialize(mode : MediaPlayerMode = MediaPlayerMode::Multiple)
            @mode = mode
            @equalizer = Equalizer.new
            if @mode == MediaPlayerMode::Single
                @obj = LibVlc.new_media_player Player.instance.obj
                LibVlc.set_media_player_equalizer @obj, @equalizer.obj
            else
                @obj = LibVlc.new_media_list_player Player.instance.obj
                LibVlc.set_media_player_equalizer media_player(), @equalizer.obj
            end
        end

        private def media_player()
            LibVlc.get_media_list_player_media_player(@obj)
        end





        def play
            if @mode == MediaPlayerMode::Single
                LibVlc.play_media_player @obj
            else
                LibVlc.play_media_list_player @obj
            end
        end

        def pause(should_pause : Bool)
            option = should_pause ? 1 : 0
            if @mode == MediaPlayerMode::Single
                LibVlc.set_media_player_pause @obj, option
            else
                LibVlc.set_media_list_player_pause @obj, option
            end
        end

        def pause
            if @mode == MediaPlayerMode::Single
                LibVlc.pause_media_player @obj
            else
                LibVlc.pause_media_list_player @obj
            end
        end

        def stop() : Bool
            if @mode == MediaPlayerMode::Single
                LibVlc.stop_media_player(@obj) == 0
            else
                LibVlc.stop_media_list_player(@obj) == 0
            end
        end




        def set(media : Media | MediaList)
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

        def get!() : Media | MediaList
            @media.as(Media | MediaList)
        end

        def get() : Media | MediaList | Nil
            @media
        end

        def list() : MediaList | Nil
            if @mode == MediaPlayerMode::Single
                raise "The media player does not contain a list of media, it just contains a single item. Did you want to call get()?"
            else
                @media.as(MediaList)
            end
        end

        def list!() : MediaList
            list().as(MediaList)
        end

        # Will only work for the multiple mode
        def previous()
            if @mode == MediaPlayerMode::Single
                raise "Not allowed for MediaPlayerMode Single"
            else
                LibVlc.previous_media_list_player(@obj) == 0
            end 
        end

        # Will only work for the multiple mode
        def next()
            if @mode == MediaPlayerMode::Single
                raise "Not allowed for MediaPlayerMode Single"
            else
                LibVlc.next_media_list_player(@obj) == 0
            end
        end

        def next_frame()
            if @mode == MediaPlayerMode::Single
                LibVlc.next_media_player_frame @obj
            else
                LibVlc.next_media_player_frame media_player()
            end  
        end


        def set_playback_mode(mode : LibVlc::PlaybackMode)
            LibVlc.set_media_list_player_playback_mode @obj, mode
        end




        #############Events#####################

        def on(event : LibVlc::Event, proc : LibVlc::Callback, user_data = nil)
            
            if event.to_i >= 0x100 && event.to_i < 0x200
                if @mode == MediaPlayerMode::Single
                    mng = LibVlc.get_media_player_event_manager @obj
                else
                    mng = LibVlc.get_media_player_event_manager media_player()
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
                    mng = LibVlc.get_media_player_event_manager media_player()
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




        ############Graphics################

        # Linux only, xwindow id
        def set_window(id : LibC::UInt32T)
            if @mode == MediaPlayerMode::Single
                LibVlc.set_media_player_xwindow @obj, id
            else
                LibVlc.set_media_player_xwindow media_player(), id
            end           
        end
        # Linux only, xwindow id
        def get_window()
            if @mode == MediaPlayerMode::Single
                LibVlc.get_media_player_xwindow @obj
            else
                LibVlc.get_media_player_xwindow media_player()
            end           
        end



        ##########Time###############

        # 0 <= percentage <= 1
        def set_position(percentage, fast = true)
            if @mode == MediaPlayerMode::Single
                LibVlc.set_media_player_position(@obj, percentage, fast)
            else
                LibVlc.set_media_player_position(media_player(), percentage, fast)
            end
        end

        # time in milliseconds
        def set_time(time : LibVlc::Time, fast = true)
            if @mode == MediaPlayerMode::Single
                LibVlc.set_media_player_time(@obj, time, fast)
            else
                LibVlc.set_media_player_time(media_player(), time, fast)
            end
        end   

        def get_position()
            if @mode == MediaPlayerMode::Single
                LibVlc.get_media_player_position(@obj)
            else
                LibVlc.get_media_player_position(media_player())
            end
        end     

        # time in milliseconds
        def get_time() : LibVlc::Time
            if @mode == MediaPlayerMode::Single
                LibVlc.get_media_player_time(@obj)
            else
                LibVlc.get_media_player_time(media_player())
            end
        end

        # time in milliseconds
        def get_length() : LibVlc::Time
            if @mode == MediaPlayerMode::Single
                LibVlc.get_media_player_length(@obj)
            else
                LibVlc.get_media_player_length(media_player())
            end
        end

        def set_speed(speed)
            set_rate(speed)
        end

        def set_rate(rate)
            if @mode == MediaPlayerMode::Single
                LibVlc.set_media_player_rate(@obj, rate)
            else
                LibVlc.set_media_player_rate(media_player(), rate)
            end
        end 

        def set_volume(volume)
            if @mode == MediaPlayerMode::Single
                LibVlc.set_audio_volume(@obj, volume)
            else
                LibVlc.set_audio_volume(media_player(), volume)
            end
        end 

        def get_volume()
            if @mode == MediaPlayerMode::Single
                LibVlc.get_audio_volume(@obj)
            else
                LibVlc.get_audio_volume(media_player())
            end
        end

        def increase_volume()
            set_volume(Math.max(0,get_volume()-5))
        end

        def decrease_volume()
            set_volume(Math.min(100,get_volume()+5))
        end

        def get_formatted_length(format : Time::Format = Time::Format.new("%M:%S")) : String
            format.format(Time.unix_ms(get_length()))
        end

        def get_state() : LibVlc::State
            if @mode == MediaPlayerMode::Single
                LibVlc.get_media_player_state(@obj)
            else
                LibVlc.get_media_player_state(media_player())
            end
        end

        def is_seekable?() : Bool
            if @mode == MediaPlayerMode::Single
                LibVlc.is_media_player_seekable?(@obj)
            else
                LibVlc.is_media_player_seekable?(media_player())
            end
        end

        def is_playing?() : Bool
            if @mode == MediaPlayerMode::Single
                LibVlc.is_media_player_playing?(@obj)
            else
                LibVlc.is_media_player_playing?(media_player())
            end
        end

        def can_pause?() : Bool
            if @mode == MediaPlayerMode::Single
                LibVlc.can_media_player_pause?(@obj)
            else
                LibVlc.can_media_player_pause?(media_player())
            end
        end


        ########Equalizer###########

        def set_equalizer(equalizer)
            if @mode == MediaPlayerMode::Single
                LibVlc.set_media_player_equalizer(@obj, equalizer.obj)
            else
                LibVlc.set_media_player_equalizer(media_player(), equalizer.obj)
            end
            @equalizer = equalizer
        end

        def get_equalizer
            @equalizer
        end



        def finalize
            if @mode == MediaPlayerMode::Single
                LibVlc.free_media_player @obj
            else
                LibVlc.free_media_list_player @obj
            end
        end
    end



    class Equalizer
        property obj
        getter obj
        def initialize
            @obj = LibVlc.new_equalizer
        end

        def initialize(preset)
            @obj = LibVlc.new_equalizer_from_preset preset
        end

        def self.preset_count
            LibVlc.get_equalizer_preset_count
        end

        def self.preset_name(index)
            LibVlc.get_equalizer_preset_name index
        end

        def self.preset_names
            presets = preset_count
            names = Array(String).new(presets)
            presets.times do |index|
                names << String.new preset_name(index)
            end
            names
        end

        def band_count()
            LibVlc.get_equalizer_band_count
        end

        def band_frequency(band)
            LibVlc.get_equalizer_band_frequency band
        end

        def get_band_amplitude(band)
            LibVlc.get_equalizer_amp_at_index @obj, band
        end

        def set_band_amplitude(band, amp)
            LibVlc.set_equalizer_amp_at_index @obj, amp, band
        end

        def set_band_amplitudes(amps)
            if amps.size != band_count()
                false
            else
                amps.each_with_index do |amp, index|
                    set_band_amplitude(index,amp)
                end
            end
        end

        def get_pre_amplitude
            LibVlc.get_equalizer_preamp @obj
        end

        def set_pre_amplitude(amp)
            LibVlc.get_equalizer_preamp @obj, amp
        end

        def finalize
            LibVlc.free_equalizer @obj
        end
    end

    enum MediaPlayerMode
        Single
        Multiple
    end

end
