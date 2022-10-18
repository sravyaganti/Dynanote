using Sound: soundsc
using WAV: wavread
using FFTW; fft
using Plots
include("Proj2_transcriber_fin.jl")

file = "touch.wav"
(x, S, _, _) = wavread(file)
N = length(x); S = 8192

errors = zeros(Int, 10); SNR = zeros(10)
for level=1:10 # 10 different noise levels
    noisesum = 0
    for trial=1:100 # 100 trials for each noise level
        noise = 5 * level * randn(size(x))
        global y = x + noise # this will be very noisy!
        noisesum += sum(noise.^2)
        # apply your transcriber to signal "y" here
        global value = (transcriber(y)[1] != "7")
        if value == true
            errors[level] += 1
        end
    end
    SNR[level] = 10 * log10(sum(x.^2) / (noisesum/100))
end
plot(SNR, errors, marker=:circle, title = "Transcriber error rate vs SNR", xlabel = "SNR[dB]", ylabel = "% errors")