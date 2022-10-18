using Sound: soundsc
using WAV: wavread
using FFTW; fft
using Plots

S = 8192
x = cos.(2pi*(1:4096)*696/S) .+ cos.(2pi*(1:4096)*1210/S) 
soundsc(x, S) #play signal 1
errors = zeros(Int, 10)
snr  = zeros(10)

for level=1:10 #10 different noise levels
    noisesum = 0
    for trial=1:100 # 100 trials for each noise level
        noise  = 5 * level * randn(size(x))
        y = x + noise
        soundsc(y,S) #play signal 1 with noise
        noise += sum(noise.^2)
        # apply our transcriber to the signal here
        if "output does != 1"
            errors[level] += 1
        end
    end
    snr[level] = 10*log10(sum(x.^2) / (noisesum/100))
end
plot(snr, errors, marker=:circle, xlabel = "SNR [dB]", ylabel = "% errors")