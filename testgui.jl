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

song = nothing # initialize "song"
global data = Float32[]

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
        # soundsc(Snew, S)
        return Snew
    else
        octaves +=1
        y = phase_vocoder(data, S; hopin=121, hopout=(octaves*121))
        Y = y[1:octaves:end]
        # soundsc(Y, S)
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
    # soundsc(Snew, S)
    return Snew
end

S = 44100
y, S = record(1)
N = length(y)

Y = abs.(2/N*real(fft(y)))
n = 1+(N÷2)
Yy = Y[1:n]
A, freq = findmax(Yy)

@show freq
# plot(Yy)

midi = round(69 + 12*log2(freq/440))
println(midi)

white = ["F" 53; "G" 55; "A" 57; "B" 59; "C" 60; "D" 62; "E" 64;"F" 65; "G" 67; "A" 69; "B" 71; "C" 72; "D" 74; "E" 76;"F" 77]
black = ["F" 54 2; "G" 56 4; "A" 58 6; "C" 61 10; "D" 63 12;"F" 66 16; "G" 68 18; "A" 70 20; "C" 73 24; "D" 75 26]

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

sounds = Vector{Vector{Float32}}()

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


# function miditone(midi::Int; nsample::Int = 2000)
#     f = 440 * 2^((midi- 69)/12) # compute frequency from midi number 
#     x = cos.(2pi*(1:nsample)*f/S) # generate sinusoidal tone
#     soundsc(x, S) # play note so that user can hear it immediately
#     global data = [data; x] # append note to the (global) song vector
#     return nothing
# end


# define the white and black keys and their midi numbers 
# white = ["F" 53; "G" 55; "A" 57; "B" 59; "C" 60; "D" 62; "E" 64;"F" 65; "G" 67; "A" 69; "B" 71; "C" 72; "D" 74; "E" 76;"F" 77]
# black = ["F" 54 2; "G" 56 4; "A" 58 6; "C" 61 10; "D" 63 12;"F" 66 16; "G" 68 18; "A" 70 20; "C" 73 24; "D" 75 26]


g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)

# CONFIGURING THE GUI
# define the "style" of the black keys
sharp = GtkCssProvider(data="#wb {color:white; background:black;}")

# for i in 1:size(white,1) # add the white keys to the grid
#     key, midi = white[i,1:2]
#     b = GtkButton(key) # make a button for this key
#     signal_connect((w) -> miditone(midi), b, "clicked") # callback
#     g[(1:2) .+ 2*(i-1), 15] = b # put the button in row 2 of the grid
# end
function get_sound(index)
    soundsc(sounds[index], S)
    global data = [data; sounds[index]]
    return sounds[index]
end
#######################################################
#WHITE buttons

b = GtkButton("F") # make a button for this key
signal_connect((w) -> get_sound(1), b, "clicked") # callback
g[(1:2) .+ 2*(1-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("G") # make a button for this key
signal_connect((w) -> get_sound(3), b, "clicked") # callback
g[(1:2) .+ 2*(2-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("A") # make a button for this key
signal_connect((w) -> get_sound(5), b, "clicked") # callback
g[(1:2) .+ 2*(3-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("B") # make a button for this key
signal_connect((w) -> get_sound(7), b, "clicked") # callback
g[(1:2) .+ 2*(4-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("C") # make a button for this key
signal_connect((w) -> get_sound(8), b, "clicked") # callback
g[(1:2) .+ 2*(5-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("D") # make a button for this key
signal_connect((w) -> get_sound(10), b, "clicked") # callback
g[(1:2) .+ 2*(6-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("E") # make a button for this key
signal_connect((w) -> get_sound(12), b, "clicked") # callback
g[(1:2) .+ 2*(7-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("F") # make a button for this key
signal_connect((w) -> get_sound(13), b, "clicked") # callback
g[(1:2) .+ 2*(8-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("G") # make a button for this key
signal_connect((w) -> get_sound(15), b, "clicked") # callback
g[(1:2) .+ 2*(9-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("A") # make a button for this key
signal_connect((w) -> get_sound(17), b, "clicked") # callback
g[(1:2) .+ 2*(10-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("B") # make a button for this key
signal_connect((w) -> get_sound(19), b, "clicked") # callback
g[(1:2) .+ 2*(11-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("C") # make a button for this key
signal_connect((w) -> get_sound(20), b, "clicked") # callback
g[(1:2) .+ 2*(12-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("D") # make a button for this key
signal_connect((w) -> get_sound(22), b, "clicked") # callback
g[(1:2) .+ 2*(13-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("E") # make a button for this key
signal_connect((w) -> get_sound(24), b, "clicked") # callback
g[(1:2) .+ 2*(14-1), 15] = b # put the button in row 2 of the grid

b = GtkButton("F") # make a button for this key
signal_connect((w) -> get_sound(25), b, "clicked") # callback
g[(1:2) .+ 2*(15-1), 15] = b # put the button in row 2 of the grid
# ##############################################################
# #BLACK keys
b = GtkButton("F" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(2), b, "clicked") # callback
g[2 .+ (0:1), 14] = b # put the button in row 1 of the grid

b = GtkButton("G" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(4), b, "clicked") # callback
g[4 .+ (0:1), 14] = b # put the button in row 1 of the grid

b = GtkButton("A" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(6), b, "clicked") # callback
g[6 .+ (0:1), 14] = b # put the button in row 1 of the grid

b = GtkButton("C" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(9), b, "clicked") # callback
g[10 .+ (0:1), 14] = b # put the button in row 1 of the grid

b = GtkButton("D" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(11), b, "clicked") # callback
g[12 .+ (0:1), 14] = b # put the button in row 1 of the grid

b = GtkButton("F" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(14), b, "clicked") # callback
g[16 .+ (0:1), 14] = b # put the button in row 1 of the grid

b = GtkButton("G" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(16), b, "clicked") # callback
g[18 .+ (0:1), 14] = b # put the button in row 1 of the grid

b = GtkButton("A" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(18), b, "clicked") # callback
g[20 .+ (0:1), 14] = b # put the button in row 1 of the grid

b = GtkButton("C" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(21), b, "clicked") # callback
g[24 .+ (0:1), 14] = b # put the button in row 1 of the grid

b = GtkButton("D" * "♯") # to make ♯ symbol, type \sharp then hit <tab>
push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
set_gtk_property!(b, :name, "wb") # set "style" of black key
signal_connect((w) -> get_sound(23)
, b, "clicked") # callback
g[26 .+ (0:1), 14] = b # put the button in row 1 of the grid




# for i in 1:size(black,1) # add the black keys to the grid
#     key, midi, start = black[i,1:3] 
#     b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>
#     push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
#     set_gtk_property!(b, :name, "wb") # set "style" of black key
#     signal_connect((w) -> miditone(midi), b, "clicked") # callback
#     g[start .+ (0:1), 14] = b # put the button in row 1 of the grid
# end
function call_play(w) # callback function for "end" button
    println("Play")
    @async sound(song, S) # play the entire recording
    soundsc(data, S)
    matwrite("proj1.mat", Dict("song" => song); compress=true) # save song to file 
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

bp = make_button("Play", call_play, 16:18, "wg", "color:white; background:black;")
win = GtkWindow("DAW", 1000, 1000); # 400×300 pixel window for all the buttons
push!(win,g) # put button grid into the window
Gtk.showall(win); # display the window full of buttons