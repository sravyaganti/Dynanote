using Sound: phase_vocoder, soundsc, hann, record
using DSP: spectrogram
using MIRTjim: jim, prompt
using InteractiveUtils: versioninfo
using FFTW: fft, ifft
using WAV
using Plots

plotly();


function pitch_increase(data, octaves, steps)
    # S = 44100
    # t = (1:S/2)/S
    # data = cos.(2*pi*440*t)

    N = length(data)
    # data, S = wavread("proj3test.wav")
    # soundsc(data,S)
    if steps > 0
        octaves = octaves + 2
        y = phase_vocoder(data, S; hopin=121, hopout=(octaves*121))
        Y = y[1:octaves:end]
        N = length(Y)
        steps = 12 - steps
        N2 = round(Int, N * (-1 + (2^(steps/12))))

        mod(N,2) == 0 || throw("N must be multiple of 2")
        F = fft(Y) # original spectrum
        Fnew = [F[1:N÷2]; zeros(N2); F[(N÷2+1):N]]
        Snew = 2 * real(ifft(Fnew))[1:N]
        return Snew
        # @show length(Snew)
        # soundsc(Snew, S)
    else
        octaves +=1
        y = phase_vocoder(data, S; hopin=121, hopout=(octaves*121))
        Y = y[1:octaves:end]
        return Y
        # @show length(Y)
        # soundsc(Y,S)

    end
end
function pitch_decrease(data, octaves, steps)
    # S = 44100
    # t = (1:S/2)/S
    # data = cos.(2*pi*440*t)
    # data, S = wavread("proj3test.wav")
    # soundsc(data,S)   
    N = length(data)
    
    octaves = octaves - 1
    N2 = round(Int, N * (octaves + (2^(steps/12))))

    mod(N,2) == 0 || throw("N must be multiple of 2")
    F = fft(data) # original spectrum
    Fnew = [F[1:N÷2]; zeros(N2); F[(N÷2+1):N]]
    Snew = 2 * real(ifft(Fnew))[1:N]
    return Snew
    # @show length(Snew)
    # soundsc(Snew, S)
    
end

S = 44100
# y, S = record(1)
N = length(y)

Y = abs.(2/N*real(fft(y)))
n = 1+(N÷2)
Yy = Y[1:n]
A, freq = findmax(Yy)

@show freq
plot(Yy)

midi = round(69 + 12*log2(freq/440))
println(midi)

keys = [53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77]
indexArr = indexin(midi, keys)
position = 0
if (indexArr .== nothing)
    if (midi < keys[1])
         position = 1
    else
        position = length(keys)
    end
else 
    position = indexArr[1]
end
@show position
# octaves = floor((position-1)/12)
# steps = mod((position - 1), 12)
sounds = Vector{Vector{Float32}}()
# push!(sounds, y)
# soundsc(sounds[1], S)
for i in 1:position
    octaves = floor((position - i)/12)
    steps = mod((position - i), 12)
    tone = pitch_decrease(y, octaves, steps)
    push!(sounds, tone)
    
end
position = position + 1
for j in position:length(keys)
    octaves = floor(Int64, j/12)
    steps = mod(j, 12)
    tone = pitch_increase(y, octaves, steps)
    push!(sounds, tone)
end

soundsc(sounds[8], S)