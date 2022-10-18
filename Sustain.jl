#Niko Economos, ENGR 100
using Sound: soundsc, record
using DSP: spectrogram
using MIRTjim: jim, prompt
using InteractiveUtils: versioninfo
using FFTW: fft, ifft
using WAV: wavread
using Plots; default(label="")


function find_envelope(x, h::Int = 101) # sliding window half-width
    x = abs.(x)
    return [zeros(h);
    [sum(x[(n-h):(n+h)]) / (2h+1) for n in (h+1):(length(x)-h)];
    zeros(h)]
    
end

function get_num_samples(note_type, bpm)

    notes = Dict("whole" => 240, "half" => 120, "quarter" => 60, "eighth" => 30, "sixteenth" => 15)
    S = 44100

    return (get(notes, note_type, 0)/bpm)*S
end


function test(data)
    S = 44100
    
    #t = (1:S/2)/S
    #data = cos.(2*pi*440*t)

    # file = "piano_note.wav"
    # (data, S, _, _) = wavread(file)
    # data = data[:, 1]

    

    N = length(data)
    #data = reshape(vec(data), length(data), 1) #for spectrogram
    D2 = 2/N * fft(data, 1)
    #soundsc(data, S)


    #PLOT ANALYSIS
    plotly();
    p1 = plot(abs.(D2), xlabel="frequency index l=k+1", ylabel="|Y[l]|")
    xlims!(1, 1+N÷2);
    p2 = heatmap(abs.(D2), xlabel="time segment", ylabel="l=k+1", clims=(0,0.00015)) # 
    ylims!(1,16000);
    p3 = plot(data, ylabel="amplitude", xlabel = "sample")
    env = find_envelope(data)
    p4 = plot((1:N)/S, env, label="envelope", xlabel="t [sec]")
    title!("Sound Envelope for a Middle C Piano Note")

    plot(p1,p2,p3,p4)


    # Take start and fin sample
    # for each element between start and end, add append them to the spot between the final sample x amount of time

    start = 15000
    finish = 75000
    modified_data = vec(data)[1:finish]

    
    numrepetitions = 2;
    for n in 1:numrepetitions
        append!(modified_data, reverse(data[start:finish]))
        append!(modified_data, data[start:finish])
    end
    append!(modified_data, data[finish:end])

    soundsc(data, S)
    soundsc(modified_data, S)
    plot(modified_data, ylabel="amplitude", xlabel = "sample")
    vline!([start], color = "green")
    vline!([finish], color = "red")

end

function sustain(data)
    
    start = 50000
    finish = 350000

    modified_data = vec(data)[1:finish]

    numrepetitions = 2;
    for n in 1:numrepetitions
        append!(modified_data, reverse(data[start:finish]))
        append!(modified_data, data[start:finish])
    end
    append!(modified_data, data[finish:end])
end

    
data, S = record(2);
bpm = 60
sustain(data, 15000, 75000, "quarter",bpm)