using Sound: soundsc
using WAV: wavread
using FFTW; fft
using Plots; default(label="")
plotly();

#read in the tone file
file = "project2.wav"
(X, S,) = wavread(file)
soundsc(X, S)

#reshape the matrix and plot based on the length of the tones
@show N = (length(X) ÷ 12)
y = reshape(X, N, 12)
plot(y[1:100, 1])

#use FFT to find freqeuncies
f = (0:N-1) / N * S
f2 = fft(y, 1)
freq = abs.(f2)
plot(freq)
xlims!(1,1200)

#Iterate through and find the two freqeuncies for each tone
for i in 1:12
    Y = freq[:,i]
    c = 2:N÷2
    #n = Z[:,i]
    min = 10;
    peak = @. (Y[c] > Y[c-1]) & (Y[c] > Y[c+1]) & (Y[c] > min)
    @show i, f[c[peak]]
end 
