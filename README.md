# mediaplayer

TODO: Write a description here

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     mediaplayer:
       github: data-niklas/mediaplayer
   ```

2. Run `shards install`

## Usage

```crystal
require "mediaplayer"
```
In the Player module, following classes are exposed:
- Instance
- Media
- MediaList
- MediaPlayer
- Equalizer

The MediaPlayer is either a (VLC) MediaListPlayer or (VLC) MediaPlayer, depending on the selected mode. By default it will be a MediaListPlayer.<br>

Simple Example:<br>
```
player = Player::MediaPlayer.new
media = Player::Media.new "/home/user/some/path/to/file/or/dir"
player.set media
player.play
sleep 10
player.stop
```
<br>
Event handling:<br>

```
player.on LibVlc::Event::MediaPlayerEndReached, LibVlc::Callback.new{ |event_data, user_data|
  puts "Song finished"
  WrappingModule.call_finish_function(event_data, user_data)
}
```

<br>
Due to the callback being passed to the c library, variables cannot be accessed in the callback.<br>
One of the easiest methods to use the callback, is to call a function in a wrapping module with the variables in the callback.<br>
Inside of the called function, other variables of the Module can now be accessed again.<br>

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/mediaplayer/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Niklas Loeser](https://github.com/your-github-user) - creator and maintainer
