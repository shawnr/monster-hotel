-- Monster Hotel - Music System
-- Plays two background tracks in alternating loop

MusicSystem = {}

MusicSystem.tracks = {}
MusicSystem.currentTrack = 1
MusicSystem.started = false

function MusicSystem:init()
    -- Load both music tracks
    self.tracks[1] = playdate.sound.fileplayer.new("audio/music/martinis-to-mars")
    self.tracks[2] = playdate.sound.fileplayer.new("audio/music/bossa-nova")
    self.currentTrack = 1
    self.started = false

    -- Verify tracks loaded
    if not self.tracks[1] then
        print("MusicSystem: failed to load track 1")
    end
    if not self.tracks[2] then
        print("MusicSystem: failed to load track 2")
    end

    -- Set up finish callbacks for alternating playback
    if self.tracks[1] then
        self.tracks[1]:setFinishCallback(function()
            self:playNextTrack()
        end)
    end
    if self.tracks[2] then
        self.tracks[2]:setFinishCallback(function()
            self:playNextTrack()
        end)
    end

    -- Start playing the first track
    self:startPlaying()
end

function MusicSystem:startPlaying()
    if self.tracks[self.currentTrack] then
        self.tracks[self.currentTrack]:play(1)  -- Play once, callback will handle next
        self.started = true
        print("MusicSystem: playing track " .. self.currentTrack)
    end
end

function MusicSystem:playNextTrack()
    -- Switch to the other track
    if self.currentTrack == 1 then
        self.currentTrack = 2
    else
        self.currentTrack = 1
    end

    -- Play the next track
    if self.tracks[self.currentTrack] then
        self.tracks[self.currentTrack]:play(1)  -- Play once, callback will handle next
        print("MusicSystem: switched to track " .. self.currentTrack)
    end
end

-- Safety net: restart if music stopped unexpectedly
function MusicSystem:ensurePlaying()
    local anyPlaying = false
    for i = 1, 2 do
        if self.tracks[i] and self.tracks[i]:isPlaying() then
            anyPlaying = true
            break
        end
    end

    if not anyPlaying and self.started then
        print("MusicSystem: restarting playback")
        self:startPlaying()
    end
end

return MusicSystem
