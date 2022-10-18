using Gtk
using Sound: sound
using WAV: wavread
using WAV: wavwrite

S = 8192 # sampling rate (samples/second) for this low-fi project
tone = Float32[] # initialize "tone" as an empty vector

function tones(f1::Real, f2::Real, nsample::Int = 4096)
    x = cos.(2pi*(1:nsample)*f1/S) .+ sin.(2pi*(1:nsample)*f2/S) # generate sinusoidal tone
    sound(x, S) # play note so that user can hear it immediately
    global tone = [tone; x] # append note to the (global) tone vector
    return nothing
end

# define the white and black keys and their midi numbers
first_line = ["1" 697 1209; "2" 697 1336; "3" 697 1477]
second_line = ["4" 770 1209; "5" 770 1336; "6" 770 1477]
third_line = ["7" 852 1209; "8" 852 1336; "9" 852 1477]
fourth_line = ["*" 941 1209; "0" 941 1336; "#" 941 1477]

g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons

set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)


sharp = GtkCssProvider(data="#wb {color:black; background:white;}")
endbut = GtkCssProvider(data="#wb {color:black; background:white;}")
clearbut = GtkCssProvider(data="#wb {color:black; background:red;}")

for i in 1:size(first_line,1)
    key, f1, f2 = first_line[i,1:3]
    b = GtkButton(key) # make a button for this key
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") 
    signal_connect((w) -> tones(f1,f2), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 1] = b 
end

for i in 1:size(second_line,1) 
    key, f1, f2 = second_line[i,1:3]
    b = GtkButton(key)
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb")
    signal_connect((w) -> tones(f1,f2), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 2] = b # put the button in row 2 of the grid
end

for i in 1:size(third_line,1)
    key, f1, f2= third_line[i,1:3]
    b = GtkButton(key)
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") 
    signal_connect((w) -> tones(f1,f2), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 3] = b # put the button in row 3 of the grid
end

for i in 1:size(fourth_line,1)
    key, f1, f2 = fourth_line[i,1:3]
    b = GtkButton(key)
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb")
    signal_connect((w) -> tones(f1,f2), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 4] = b # put the button in row 4 of the grid
end

function end_button_clicked(w) # callback function for "end" button
    println("The end button")
    sound(tone, S) # play the entire number when user clicks "end"
    wavwrite(tone, "touch.wav"; Fs=S) # save number to file
end

function clear_button_clicked(w) # callback for clear, sets tone to an empty array
    println("The clear button")
    global tone = Float32[];
end

ebutton = GtkButton("dial") # make an "end" button
g[1:4, 5] = ebutton
clearbutton = GtkButton("clear")# make a "clear" button
g[4:6, 5] = clearbutton

set_gtk_property!(clearbutton, :name, "wb")
signal_connect(clear_button_clicked, clearbutton, "clicked")
push!(GAccessor.style_context(clearbutton), GtkStyleProvider(clearbut), 600)

set_gtk_property!(ebutton, :name, "wb")
signal_connect(end_button_clicked, ebutton, "clicked") # callback
push!(GAccessor.style_context(ebutton), GtkStyleProvider(endbut), 400)


win = GtkWindow("gtk3", 400, 300) # 400×300 pixel window for all the buttons
push!(win, g) # put button grid into the window
showall(win); # display the window full of buttons
