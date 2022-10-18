using Gtk: GtkGrid, GtkButton, GtkWindow, GAccessor, GtkScale
using Gtk: GtkCssProvider, GtkStyleProvider, GtkImage
using Gtk: set_gtk_property!, signal_connect, showall
using PortAudio: PortAudioStream
using MAT: matwrite
using Gtk.ShortNames, GtkReactive
using PNGFiles
using Sound: phase_vocoder, hann, record, sound, soundsc
using DSP: spectrogram
using MIRTjim: jim, prompt
using InteractiveUtils: versioninfo
using FFTW: fft, ifft
using MIRT: interp1

notneeded = Float32[]

const S = 44100 # sampling rate (samples/second)
const N = 1024 # buffer length
const maxtime = 10 # maximum recording time 10 seconds (for demo)
recording = nothing # flag
nsample = 0 # count number of samples recorded
global song # initialize "song"
global data

function pitch_increase(data, octaves, steps)
    N = length(data)
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
    else
        octaves +=1
        y = phase_vocoder(data, S; hopin=121, hopout=(octaves*121))
        Y = y[1:octaves:end]
        return Y
    end
end
function pitch_decrease(data, octaves, steps)  
    N = length(data)
   
    octaves = octaves - 1
    N2 = round(Int, N * (octaves + (2^(steps/12))))
  
    mod(N,2) == 0 || throw("N must be multiple of 2")
    F = fft(data) # original spectrum
    Fnew = [F[1:N÷2]; zeros(N2); F[(N÷2+1):N]]
    Snew = 2 * real(ifft(Fnew))[1:N]
    return Snew
end


# define the white and black keys and their midi numbers 
white = ["F" 53; "G" 55; "A" 57; "B" 59; "C" 60; "D" 62; "E" 64;"F" 65; "G" 67; "A" 69; "B" 71; "C" 72; "D" 74; "E" 76;"F" 77]
black = ["F" 54 2; "G" 56 4; "A" 58 6; "C" 61 10; "D" 63 12;"F" 66 16; "G" 68 18; "A" 70 20; "C" 73 24; "D" 75 26]


g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)

# CONFIGURING THE GUI
# define the "style" of the black keys
sharp = GtkCssProvider(data="#wb {color:white; background:black;}")
#  add a style for the end button
label = Label("Hello")
clearbut = GtkCssProvider(data="#wb {color:white; background:black;}")
reverbbut = GtkCssProvider(data="#wb {color:white; background:black;}")
delaybut = GtkCssProvider(data="#wb {color:white; background:black;}")
adsrbut = GtkCssProvider(data="#wb {color:white; background:black;}")
attackdecaybut = GtkCssProvider(data="#wb {color:white; background:black;}")
releasebut = GtkCssProvider(data="#wb {color:white; background:black;}")
tremolobut = GtkCssProvider(data="#wb {color:white; background:black;}")
sustainbut = GtkCssProvider(data="#wb {color:white; background:black;}")
logobut = GtkCssProvider(data="#wb {color:white; background:black;}")
whole_note_but = GtkCssProvider(data="#wb {color:white; background:black;}")
half_note_but = GtkCssProvider(data="#wb {color:white; background:black;}")
quarter_note_but = GtkCssProvider(data="#wb {color:white; background:black;}")
eighth_note_but = GtkCssProvider(data="#wb {color:white; background:black;}")
sixteenth_note_but = GtkCssProvider(data="#wb {color:white; background:black;}")
run_but = GtkCssProvider(data="#wb {color:black; background:white;}")

global b;

function call_play(w) # callback function for "end" button
    println("Play")
    @async sound(song, S) # play the entire recording
end

function call_stop(w)
    global recording = false
    global nsample
    duration = round(nsample / S, digits=2)
    sleep(0.1) # ensure the async record loop finished
    flush(stdout)
    println("\nStop at nsample=$nsample, for $duration out of $maxtime sec.")
    global song = song[1:nsample] # truncate song to the recorded duration
end

function call_play_1(w) # callback function for "end" button
    println("Play")
    @async sound(data, S) # play the entire recording
 
end
function call_record(w)
    global N
    in_stream = PortAudioStream(1, 0) # default input device
    buf = read(in_stream, N) # warm-up
    global recording = true
    global song = zeros(Float32, maxtime * S)
    @async record_loop!(in_stream, buf)
    @show length(song)
    global song = song[1:400000]
    nothing
end

function make_button(string, callback, column, stylename, styledata)
    b = GtkButton(string)
    signal_connect((w) -> callback(w), b, "clicked")
    g[column,3:4] = b
    s = GtkCssProvider(data = "#$stylename {$styledata}")
    push!(GAccessor.style_context(b), GtkStyleProvider(s), 600)
    set_gtk_property!(b, :name, stylename)
    return b
end

br = make_button("Record", call_record, 10:12, "wr", "color:white; background:black;")
bs = make_button("Stop", call_stop, 13:15, "yb", "color:white; background:black;")
bp = make_button("Play", call_play, 16:18, "wg", "color:white; background:black;")

function record_loop!(in_stream, buf)
    global maxtime = 1
    global S
    global N
    global recording
    global nsample
    Niter = floor(Int, 0.5 * S / N)
    println("\nRecording up to Niter=$Niter ($maxtime sec).")
    for iter in 1:Niter
        if !recording
            break
        end
        read!(in_stream, buf)
        song[(iter-1)*N .+ (1:N)] = buf # save buffer to song
        nsample += N
        print("\riter=$iter/$Niter nsample=$nsample")
    end
    nothing
end

function clear_button_clicked(w)
    println("The clear button")
    global data = Float32[];
    global song = Float32[];
    global sounds = Float32[];
end

function clear_button_clicked_2(w)
    println("The clear button")
    global data = Float32[];
end


function attack_decay_clicked(w)
    println("Attack-Decay");
    N = length(song)
    time = (0:N-1)/S
    env = (time .- exp.(-80*time)) .* exp.(-3*time) # fast attack; slow decay
    y = 8* env .* song
    global song = y
end

function ADSR_clicked(w)
    println("ADS");
    N = length(song)
    time = (0:N-1)/S
    t = (N-1)/S
    a = t * 0.12
    b = t * 0.24
    c = t * 0.84
    d = t * 1
    env = interp1([0, a, b, c, d], [0, 1, 0.4, 0.4, 0], time)
    y = 8*env .* song
    global song = y
end

function release_clicked(w)
    println("Release");
end
function reverb_clicked(w)
    println("Reverb");
    
    L= length(song)
    #determine division length for echoes
    d= (floor(L/4))
    D= trunc(Int, d)

    #add cushion zeroes to end of dataVec
    cushion = zeros(4*D)
    BaseSound= Float64[]
    append!(BaseSound, song, S)
    append!(BaseSound, cushion, S)

    EchoOne= Float64[]
    append!(EchoOne, zeros(D-1), S)
    append!(EchoOne, song, S)
    append!(EchoOne, zeros(3*D), S)
    EchoOne= EchoOne.*0.7

    EchoTwo= Float64[]
    append!(EchoTwo, zeros((2*D)-1), S)
    append!(EchoTwo, song, S)
    append!(EchoTwo, zeros(2*D), S)
    EchoTwo= EchoTwo.*0.5

    EchoThree= Float64[]
    append!(EchoThree, zeros((3*D)-1), S)
    append!(EchoThree, song, S)
    append!(EchoThree, zeros(D), S)
    EchoThree= EchoThree.*0.3

    EchoFour= Float64[]
    append!(EchoFour, zeros((4*D)-1), S)
    append!(EchoFour, song, S)
    EchoFour= EchoFour.*0.1

    finalSound=BaseSound+EchoOne+EchoTwo+EchoThree
    global song = finalSound
    sound(song, S)
    return song
end

function tremolo_clicked(w)
    println("Tremolo");
    N = length(song)
    t = (0:N-1)/S

    lfo = 0.5 .- 0.4 * cos.(2π*10*t)
    y = lfo .* song

    global song = y
end
function delay_clicked(w)
    println("Delay")
      
end

function sustain_slider(w)
    println("Sustain")

end

function whole_note(w)
    println("Whole Note")
    start = 5000
    finish = 19000

    modified_data = vec(song)[1:finish]

    numrepetitions = 3;
    for n in 1:numrepetitions
        append!(modified_data, reverse(song[start:finish]))
        append!(modified_data, song[start:finish])
    end
    append!(modified_data, song[finish:end])

    global song = modified_data
end

function half_note(w)
    println("Half Note")
    start = 5000
    finish = 19000

    modified_data = vec(song)[1:finish]

    numrepetitions = 2;
    for n in 1:numrepetitions
        append!(modified_data, reverse(song[start:finish]))
        append!(modified_data, song[start:finish])
    end
    append!(modified_data, song[finish:end]) 
    global song = modified_data
end


function quarter_note(w)
    println("Quarter Note")
    start = 5000
    finish = 19000

    modified_data = vec(song)[1:finish]

    numrepetitions = 1;
    for n in 1:numrepetitions
        append!(modified_data, reverse(song[start:finish]))
        append!(modified_data, song[start:finish])
    end
    append!(modified_data, song[finish:end])
    global song = modified_data
end

function eighth_note(w)
    #Future implementation
    println("Eight Note")
    
end

function sixteenth_note(w)
    #Future implementation
    println("Sixteenth Note")

end
function ultimate_run(w)
    
    Nn = length(song)
    println("Run")
    Y = abs.(2/Nn*real.(fft(song)))
    n = 1+(Nn÷2)
    Yy = Y[1:n]
    A, freq = findmax(Yy)

   @show freq

    midi = round(69 + 12*log2(freq/440))
    println(midi)
    # define the white and black keys and their midi numbers 
    keys = [53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77]
    indexArr = indexin(midi, keys)
    global position = 0
    if (indexArr .== nothing)
        if (midi < keys[1])
            global position = 1
        else
            global position = length(keys)
        end
    else 
        global position = indexArr[1]
    end
   
    global sounds = Vector{Vector{Float32}}()
    
    for i in 1:position
        octaves = floor((position - i)/12)
        steps = mod((position - i), 12)
        tone = pitch_decrease(song, octaves, steps)
        push!(sounds, tone)
    end
   
    global position = position + 1
    for j in position:length(keys)
        octaves = floor(Int64, j/12)
        steps = mod(j, 12)
        tone = pitch_increase(song, octaves, steps)
        push!(sounds, tone)
    end
    
    function get_sound(index)
        sound(sounds[index], S)
        global data = [data; sounds[index]]
        return sounds[index]
    end
  
    #WHITE buttons
    f = GtkGrid() # initialize a grid to hold buttons
    set_gtk_property!(f, :row_spacing, 5) # gaps between buttons
    set_gtk_property!(f, :column_spacing, 5)
    set_gtk_property!(f, :row_homogeneous, true) # stretch with window resize
    set_gtk_property!(f, :column_homogeneous, true)

    function make_button_1(string, callback, column, stylename, styledata)
        b = GtkButton(string)
        signal_connect((w) -> callback(w), b, "clicked")
        f[column,16] = b
        s = GtkCssProvider(data = "#$stylename {$styledata}")
        push!(GAccessor.style_context(b), GtkStyleProvider(s), 600)
        set_gtk_property!(b, :name, stylename)
        return b
    end

    bp = make_button_1("Play", call_play_1, 1:15, "wg", "color:white; background:black;")
    clearbutton_2 = GtkButton("Clear")
    f[16:30, 16] = clearbutton_2
    set_gtk_property!(clearbutton_2, :name, "wb")
    signal_connect(clear_button_clicked_2, clearbutton_2, "clicked")
    push!(GAccessor.style_context(clearbutton_2), GtkStyleProvider(clearbut), 600)

    b = GtkButton("F") # make a button for this key
    signal_connect((w) -> get_sound(1), b, "clicked") # callback
    f[(1:2) .+ 2*(1-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("G") # make a button for this key
    signal_connect((w) -> get_sound(3), b, "clicked") # callback
    f[(1:2) .+ 2*(2-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("A") # make a button for this key
    signal_connect((w) -> get_sound(5), b, "clicked") # callback
    f[(1:2) .+ 2*(3-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("B") # make a button for this key
    signal_connect((w) -> get_sound(7), b, "clicked") # callback
    f[(1:2) .+ 2*(4-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("C") # make a button for this key
    signal_connect((w) -> get_sound(8), b, "clicked") # callback
    f[(1:2) .+ 2*(5-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("D") # make a button for this key
    signal_connect((w) -> get_sound(10), b, "clicked") # callback
    f[(1:2) .+ 2*(6-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("E") # make a button for this key
    signal_connect((w) -> get_sound(12), b, "clicked") # callback
    f[(1:2) .+ 2*(7-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("F") # make a button for this key
    signal_connect((w) -> get_sound(13), b, "clicked") # callback
    f[(1:2) .+ 2*(8-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("G") # make a button for this key
    signal_connect((w) -> get_sound(15), b, "clicked") # callback
    f[(1:2) .+ 2*(9-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("A") # make a button for this key
    signal_connect((w) -> get_sound(17), b, "clicked") # callback
    f[(1:2) .+ 2*(10-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("B") # make a button for this key
    signal_connect((w) -> get_sound(19), b, "clicked") # callback
    f[(1:2) .+ 2*(11-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("C") # make a button for this key
    signal_connect((w) -> get_sound(20), b, "clicked") # callback
    f[(1:2) .+ 2*(12-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("D") # make a button for this key
    signal_connect((w) -> get_sound(22), b, "clicked") # callback
    f[(1:2) .+ 2*(13-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("E") # make a button for this key
    signal_connect((w) -> get_sound(24), b, "clicked") # callback
    f[(1:2) .+ 2*(14-1), 15] = b # put the button in row 2 of the grid

    b = GtkButton("F") # make a button for this key
    signal_connect((w) -> get_sound(25), b, "clicked") # callback
    f[(1:2) .+ 2*(15-1), 15] = b # put the button in row 2 of the grid
    # ##############################################################
    # #BLACK keys
    b = GtkButton("F" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(2), b, "clicked") # callback
    f[2 .+ (0:1), 14] = b # put the button in row 1 of the grid

    b = GtkButton("G" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(4), b, "clicked") # callback
    f[4 .+ (0:1), 14] = b # put the button in row 1 of the grid

    b = GtkButton("A" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(6), b, "clicked") # callback
    f[6 .+ (0:1), 14] = b # put the button in row 1 of the grid

    b = GtkButton("C" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(9), b, "clicked") # callback
    f[10 .+ (0:1), 14] = b # put the button in row 1 of the grid

    b = GtkButton("D" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(11), b, "clicked") # callback
    f[12 .+ (0:1), 14] = b # put the button in row 1 of the grid

    b = GtkButton("F" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(14), b, "clicked") # callback
    f[16 .+ (0:1), 14] = b # put the button in row 1 of the grid

    b = GtkButton("G" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(16), b, "clicked") # callback
    f[18 .+ (0:1), 14] = b # put the button in row 1 of the grid

    b = GtkButton("A" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(18), b, "clicked") # callback
    f[20 .+ (0:1), 14] = b # put the button in row 1 of the grid

    b = GtkButton("C" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(21), b, "clicked") # callback
    f[24 .+ (0:1), 14] = b # put the button in row 1 of the grid

    b = GtkButton("D" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> get_sound(23), b, "clicked") # callback
    f[26 .+ (0:1), 14] = b # put the button in row 1 of the grid

    win2 = GtkWindow("Synthesizer", 1000, 1000); # 400×300 pixel window for all the buttons
    push!(win2,f) # put button grid into the window
    Gtk.showall(win2); # display the window full of buttons
    @show ("Please")
end

clearbutton = GtkButton("Clear")
g[16:18, 7:8] = clearbutton
sustain_slider_button_1 = slider(1:0.5:10)
g[1:5, 3:4] = sustain_slider_button_1
text_box_1 = textbox(Float64; signal=signal(sustain_slider_button_1))
g[1:5, 5:6] = text_box_1
sustain_slider_button_2 = slider(1:0.5:10)
g[6:9, 3:4] = sustain_slider_button_2
text_box_2 = textbox(Float64; signal=signal(sustain_slider_button_2))
g[6:9, 5:6] = text_box_2
attack_decay_button = GtkButton("Attack-Decay")
g[1:3,9:10] = attack_decay_button
reverb_button = GtkButton("Reverb")
g[4:6, 9:10] = reverb_button 
ADSR_button  = GtkButton("ADSR")
g[1:3, 7:8] = ADSR_button 
release_button  = GtkButton("Release")
g[4:6, 7:8] = release_button
tremolo_button  = GtkButton("Tremolo")
g[7:9, 9:10] = tremolo_button
delay_button = GtkButton("Delay")
g[7:9, 7:8]= delay_button
logo_button = GtkButton("DYNANOTE")
g[1:18, 1:2]= logo_button
whole_note_button = GtkButton("Whole Note")
g[10:12, 5:6] = whole_note_button
half_note_button = GtkButton("Half Note")
g[13:15, 5:6] = half_note_button 
quarter_note_button = GtkButton("Quarter Note")
g[16:18, 5:6] = quarter_note_button
eighth_note_button = GtkButton("Eight Note")
g[10:12, 7:8] = eighth_note_button
sixteenth_note_button = GtkButton("Sixteenth Note") 
g[13:15, 7:8] = sixteenth_note_button
ultimate_run_button = GtkButton("Generate Synthesizer") 
g[1:18, 11:15] = ultimate_run_button 
img_back = GtkImage("Image .jpeg")
g[1:18,1:15] = img_back

set_gtk_property!(clearbutton, :name, "wb")
signal_connect(clear_button_clicked, clearbutton, "clicked")
push!(GAccessor.style_context(clearbutton), GtkStyleProvider(clearbut), 600)

set_gtk_property!(attack_decay_button, :name, "wb")
signal_connect(attack_decay_clicked, attack_decay_button, "clicked")
push!(GAccessor.style_context(attack_decay_button), GtkStyleProvider(adsrbut), 600)

set_gtk_property!(reverb_button, :name, "wb")
signal_connect(reverb_clicked, reverb_button, "clicked")
push!(GAccessor.style_context(reverb_button), GtkStyleProvider(reverbbut), 600)

set_gtk_property!(ADSR_button, :name, "wb")
signal_connect(ADSR_clicked, ADSR_button, "clicked")
push!(GAccessor.style_context(ADSR_button), GtkStyleProvider(adsrbut), 600)

set_gtk_property!(release_button, :name, "wb")
signal_connect(release_clicked, release_button, "clicked")
push!(GAccessor.style_context(release_button), GtkStyleProvider(releasebut), 600)

set_gtk_property!(logo_button, :name, "wb")
push!(GAccessor.style_context(logo_button), GtkStyleProvider(logobut), 600)

set_gtk_property!(tremolo_button, :name, "wb")
signal_connect(tremolo_clicked, tremolo_button, "clicked")
push!(GAccessor.style_context(tremolo_button), GtkStyleProvider(tremolobut), 600)

set_gtk_property!(delay_button, :name, "wb")
signal_connect(delay_clicked, delay_button, "clicked")
push!(GAccessor.style_context(delay_button), GtkStyleProvider(delaybut), 600)

set_gtk_property!(whole_note_button, :name, "wb")
signal_connect(whole_note, whole_note_button, "clicked")
push!(GAccessor.style_context(whole_note_button), GtkStyleProvider(whole_note_but), 600)

set_gtk_property!(half_note_button, :name, "wb")
signal_connect(half_note, half_note_button, "clicked")
push!(GAccessor.style_context(half_note_button,), GtkStyleProvider(half_note_but), 600)

set_gtk_property!(quarter_note_button, :name, "wb")
signal_connect(quarter_note, quarter_note_button, "clicked")
push!(GAccessor.style_context(quarter_note_button), GtkStyleProvider(quarter_note_but), 600)

set_gtk_property!(eighth_note_button, :name, "wb")
signal_connect(eighth_note, eighth_note_button, "clicked")
push!(GAccessor.style_context(eighth_note_button), GtkStyleProvider(eighth_note_but), 600)

set_gtk_property!(sixteenth_note_button, :name, "wb")
signal_connect(sixteenth_note, sixteenth_note_button, "clicked")
push!(GAccessor.style_context(sixteenth_note_button), GtkStyleProvider(sixteenth_note_but), 600)

set_gtk_property!(ultimate_run_button , :name, "wb")
signal_connect(ultimate_run, ultimate_run_button , "clicked")
push!(GAccessor.style_context(ultimate_run_button ), GtkStyleProvider(run_but), 600)

win = GtkWindow("DAW", 1000, 1000); # 400×300 pixel window for all the buttons
push!(win,g) # put button grid into the window
Gtk.showall(win); # display the window full of buttons

