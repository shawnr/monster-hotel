-- Monster Hotel - Music System
-- Handles background music playback with single track

MusicSystem = {}

-- Single music track (loaded once)
MusicSystem.track = nil

-- Current state
MusicSystem.isPlaying = false
MusicSystem.isGameplayMode = false

function MusicSystem:init()
    -- Load the single music track
    self.track = playdate.sound.fileplayer.new("audio/music/martinis-to-mars")
    self.isPlaying = false
    self.isGameplayMode = false

    print("MusicSystem initialized - track:", self.track)
end

function MusicSystem:playMenuMusic()
    -- If already playing menu music, don't restart
    if not self.isGameplayMode and self.isPlaying then
        return
    end

    -- Stop any current music
    self:stopAll()

    self.isGameplayMode = false

    -- Menu: loop forever
    if self.track then
        self.track:play(0)
        self.isPlaying = true
        print("Playing menu music (looping)")
    end
end

function MusicSystem:playGameplayMusic()
    -- If already in gameplay mode with music playing, don't restart
    if self.isGameplayMode and self.isPlaying then
        return
    end

    -- Stop any current music
    self:stopAll()

    self.isGameplayMode = true

    -- Gameplay: play once then stop
    if self.track then
        self.track:play(1)
        self.isPlaying = true
        print("Playing gameplay music (once)")
    end
end

-- Restart gameplay music (called on level up or new day)
function MusicSystem:restartGameplayMusic()
    -- Stop current playback
    if self.track then
        self.track:stop()
    end

    self.isGameplayMode = true
    self.isPlaying = false

    -- Play once
    if self.track then
        self.track:play(1)
        self.isPlaying = true
        print("Gameplay music restarted (once)")
    end
end

function MusicSystem:stopAll()
    if self.track then
        self.track:stop()
    end

    self.isPlaying = false
    self.isGameplayMode = false
end

function MusicSystem:pause()
    if self.track and self.isPlaying then
        self.track:pause()
    end
end

function MusicSystem:resume()
    if self.track then
        self.track:play(0)
    end
end

return MusicSystem
