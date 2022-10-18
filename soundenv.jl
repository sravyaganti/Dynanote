using MIRT: interp1
using Sound: soundsc
using Plots
using WAV: wavread



file = "/Users/ian/Documents/GitHub/engr100-trombones/piano_note.wav"
(x, S, _, _) = wavread(file)
data = x[:,1]
soundsc(data, S)

N = length(data)
time = (0:N-1)/S

function fast_attack_decay(stuff)
    N = length(stuff)
    time = (0:N-1)/S
    env = (time .- exp.(-80*time)) .* exp.(-3*time) # fast attack; slow decay
    y = 8 * env .* stuff
    return y
end

function asdr(stuff)
    N = length(stuff)
    time = (0:N-1)/S
    t = (N-1)/S
    a = t * 0.12
    b = t * 0.24
    c = t * 0.84
    d = t * 1
    env = interp1([0, a, b, c, d], [0, 1, 0.4, 0.4, 0], time)
    y = env .* stuff
    return y
end

#lol = fast_attack_decay(data)
lol = asdr(data)
soundsc(lol, S)

