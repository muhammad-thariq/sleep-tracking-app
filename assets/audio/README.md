# Alarm sound

Drop an `alarm.mp3` file in this folder to give the alarm a sound.

`AlarmService.startSound()` plays `AssetSource('audio/alarm.mp3')` in a loop
when the alarm-ringing screen opens. If the file is absent the call fails
silently — the alarm UI still appears, just without audio.

A real bundled tone isn't committed here to keep the repo free of binary blobs.
