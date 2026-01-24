-- Monster Hotel - Music System
-- Handles background music playback

MusicSystem = {}

-- Music tracks (loaded once)
MusicSystem.track1 = nil  -- bossa-spooky (menu music, also used in gameplay rotation)
MusicSystem.track2 = nil  -- spooky-bounce (gameplay starts with this)

-- Current state
MusicSystem.currentTrack = nil
MusicSystem.currentTrackNumber = 0
MusicSystem.isGameplayMode = false
MusicSystem.switchTimer = nil
MusicSystem.SWITCH_INTERVAL = 2 * 60 * 1000  -- 2 minutes in milliseconds

function MusicSystem:init()
    -- Load music tracks
    self.track1 = playdate.sound.fileplayer.new("audio/music/bossa-spooky_3")
    self.track2 = playdate.sound.fileplayer.new("audio/music/spooky-bounce_3")

    print("MusicSystem initialized - track1:", self.track1, "track2:", self.track2)
end

function MusicSystem:playMenuMusic()
    -- If already playing menu music, don't restart
    if not self.isGameplayMode and self.currentTrackNumber == 1 and self.currentTrack and self.currentTrack:isPlaying() then
        return
    end

    -- Stop any current music
    self:stopAll()

    self.isGameplayMode = false
    self.currentTrackNumber = 1

    -- Menu uses track 1 (bossa-spooky)
    if self.track1 then
        self.track1:play(0)  -- 0 = loop forever
        self.currentTrack = self.track1
        print("Playing menu music (track 1)")
    end
end

function MusicSystem:playGameplayMusic()
    -- If already in gameplay mode with music playing, don't restart
    if self.isGameplayMode and self.currentTrack and self.currentTrack:isPlaying() then
        return
    end

    -- Stop any current music
    self:stopAll()

    self.isGameplayMode = true
    self.currentTrackNumber = 2  -- Start gameplay with track 2 (spooky-bounce)

    -- Start with track 2
    self:playTrack(2)

    -- Set up timer to switch tracks every 2 minutes
    self:startSwitchTimer()
end

function MusicSystem:playTrack(trackNum)
    -- Stop current track if playing
    if self.currentTrack then
        self.currentTrack:stop()
    end

    self.currentTrackNumber = trackNum

    if trackNum == 1 then
        if self.track1 then
            self.track1:play(0)  -- Loop forever
            self.currentTrack = self.track1
            print("Playing track 1 (bossa-spooky)")
        end
    else
        if self.track2 then
            self.track2:play(0)  -- Loop forever
            self.currentTrack = self.track2
            print("Playing track 2 (spooky-bounce)")
        end
    end
end

function MusicSystem:startSwitchTimer()
    -- Cancel existing timer if any
    if self.switchTimer then
        self.switchTimer:remove()
        self.switchTimer = nil
    end

    -- Create new timer for track switching
    self.switchTimer = playdate.timer.new(self.SWITCH_INTERVAL, function()
        if self.isGameplayMode then
            self:switchGameTrack()
        end
    end)
    self.switchTimer.repeats = true
end

function MusicSystem:switchGameTrack()
    -- Toggle between tracks 1 and 2
    if self.currentTrackNumber == 1 then
        self:playTrack(2)
    else
        self:playTrack(1)
    end
    print("Switched to track", self.currentTrackNumber)
end

function MusicSystem:stopAll()
    if self.track1 then
        self.track1:stop()
    end
    if self.track2 then
        self.track2:stop()
    end

    if self.switchTimer then
        self.switchTimer:remove()
        self.switchTimer = nil
    end

    self.currentTrack = nil
    self.currentTrackNumber = 0
    self.isGameplayMode = false
end

function MusicSystem:pause()
    if self.currentTrack then
        self.currentTrack:pause()
    end
end

function MusicSystem:resume()
    if self.currentTrack then
        self.currentTrack:play(0)
    end
end

return MusicSystem
