using Gtk
using Sound: sound
using WAV: wavread
using WAV: wavwrite

S = 8192 # sampling rate (samples/second) 
tone = Float32[]

function tones(f1::Real, f2::Real, nsample::Int = 4096)
    x = cos.(2pi*(1:nsample)*f1/S) .+ cos.(2pi*(1:nsample)*f2/S) # inusoidal tone
    sound(x, S) # play note so that user can hear it immediately
    global tone = [tone; x] 
    return nothing
end

# Define keys for touch tone interface
first_line = ["1" 696 1210; "2" 698 1336; "3" 696 1478]
second_line = ["4" 770 1210; "5" 770 1336; "6" 770 1478]
third_line = ["7" 852 1210; "8" 852 1336; "9" 852 1478]
fourth_line = ["*" 940 1210; "0" 942 1336; "#" 940 1478]

g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons

set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)


sharp = GtkCssProvider(data="#wb {color:black; background:white;}")
endbut = GtkCssProvider(data="#wb {color:black; background:white;}")
clearbut = GtkCssProvider(data="#wb {color:black; background:red;}")

for i in 1:size(first_line,1) # add 1st keys to grid
    key, f1, f2 = first_line[i,1:3]
    b = GtkButton(key) # make a button for this key
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") 
    signal_connect((w) -> tones(f1,f2), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 1] = b 
end

for i in 1:size(second_line,1) # add second keys to grid
    key, f1, f2 = second_line[i,1:3]
    b = GtkButton(key) 
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") 
    signal_connect((w) -> tones(f1,f2), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 2] = b 
end

for i in 1:size(third_line,1) # add third line keys to grid
    key, f1, f2= third_line[i,1:3]
    b = GtkButton(key) 
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") 
    signal_connect((w) -> tones(f1,f2), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 3] = b 
end

for i in 1:size(fourth_line,1) # add the fourth line keys to grid
    key, f1, f2 = fourth_line[i,1:3]
    b = GtkButton(key) 
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") 
    signal_connect((w) -> tones(f1,f2), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 4] = b 
end

function end_button_clicked(w) # callback function for "end" button
    println("The end button")
    sound(tone, S) # play the entire phone number
    wavwrite(tone, "touch.wav"; Fs=S) # save phone number tones to file
end

function clear_button_clicked(w)
    println("The clear button")
    global tone = Float32[];
end

ebutton = GtkButton("dial") # make an "end" button
g[1:4, 5] = ebutton 
clearbutton = GtkButton("clear")
g[4:6, 5] = clearbutton

set_gtk_property!(clearbutton, :name, "wb")
signal_connect(clear_button_clicked, clearbutton, "clicked")
push!(GAccessor.style_context(clearbutton), GtkStyleProvider(clearbut), 600)
signal_connect(end_button_clicked, ebutton, "clicked") # callback

push!(GAccessor.style_context(ebutton), GtkStyleProvider(endbut), 400)
set_gtk_property!(ebutton, :name, "wb")

win = GtkWindow("gtk3", 400, 300) # 400×300 pixel window for all the buttons
push!(win, g) # put button grid into the window
showall(win); # display the window full of buttons
