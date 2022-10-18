using Sound: phase_vocoder, soundsc, hann, record
using DSP: spectrogram
using MIRTjim: jim, prompt
using InteractiveUtils: versioninfo
using FFTW: fft, ifft



function pitch_increase(octaves, steps)
    
    S = 44100
    t = (1:S/2)/S
    # data = cos.(2*pi*440*t)
    data, S = record(2)
    soundsc(data,S)
    
    if steps > 0
        octaves = octaves + 2
        y = phase_vocoder(data, S; hopin=121, hopout=(octaves*121))
        Y = y[1:octaves:end]
        @show length(Y)

        
        N = length(Y)
        steps = 12 - steps
        @show 0 + (2^(steps/12))
        N2 = round(Int, N * (-1 + (2^(steps/12))))

        mod(N,2) == 0 || throw("N must be multiple of 2")
        F = fft(Y) # original spectrum
        Fnew = [F[1:N÷2]; zeros(N2); F[(N÷2+1):N]]
        Snew = 2 * real(ifft(Fnew))[1:N]
        @show length(Snew)
        soundsc(Snew, S)
    else
        octaves +=1
        y = phase_vocoder(data, S; hopin=121, hopout=(octaves*121))
        Y = y[1:octaves:end]
        @show length(Y)
        soundsc(Y,S)
    end
end

function pitch_decrease(octaves, steps)
    S = 44100
    # t = (1:S/2)/S
    # data = cos.(2*pi*440*t)
    data, S = record(2)
    @show length(data)

    soundsc(data, S)
       
    N = length(data)
    
    octaves = octaves - 1
    @show octaves + (2^(steps/12))
    N2 = round(Int, N * (octaves + (2^(steps/12))))

    mod(N,2) == 0 || throw("N must be multiple of 2")
    F = fft(data) # original spectrum
    Fnew = [F[1:N÷2]; zeros(N2); F[(N÷2+1):N]]
    Snew = 2 * real(ifft(Fnew))[1:N]
    @show length(Snew)
    soundsc(Snew, S)
    
end