
using Sound: soundsc
using Plots
using WAV: wavread

time = 100
freq = 460
S = 44100
intensity = 15

file = "piano_note.wav"
(data, S, _, _) = wavread(file)
data = data[:, 1]

function tremolo(data, intensity)

    N = length(data)
    t = (0:N-1)/S

    lfo = 0.5 .- 0.4 * cos.(2π*intensity*t) # what frequency?
    y = lfo .* data

    return y
end

y = tremolo(data, intensity)
p1 = plot(y, ylabel="amplitude", xlabel = "sample")
title!("Tremolo (f = 15Hz) for a Middle C Piano Note")

soundsc(y, S)


