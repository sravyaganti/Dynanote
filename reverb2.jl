using Sound: soundsc, sound
using Plots
using WAV: wavread


function add_reverb(dataVec)
#read in music
    S = 44100
    file = "c:/Users/sravy/.julia/engr100-trombones/piano_note.wav"
    #(data, S, _, _) = wavread(file)
    #dataVec = data[:,1]

    L= length(dataVec)
    #determine division length for echoes
    d= (floor(L/4))
    D= trunc(Int, d)

    #add cushion zeroes to end of dataVec
    cushion = zeros(4*D)
    BaseSound= Float64[]
    append!(BaseSound, dataVec, S)
    append!(BaseSound, cushion, S)
    #sound(BaseSound, 44100)

    EchoOne= Float64[]
    append!(EchoOne, zeros(D-1), S)
    append!(EchoOne, dataVec, S)
    append!(EchoOne, zeros(3*D), S)
    EchoOne= EchoOne.*0.7

    EchoTwo= Float64[]
    append!(EchoTwo, zeros((2*D)-1), S)
    append!(EchoTwo, dataVec, S)
    append!(EchoTwo, zeros(2*D), S)
    EchoTwo= EchoTwo.*0.5

    EchoThree= Float64[]
    append!(EchoThree, zeros((3*D)-1), S)
    append!(EchoThree, dataVec, S)
    append!(EchoThree, zeros(D), S)
    EchoThree= EchoThree.*0.3

    EchoFour= Float64[]
    append!(EchoFour, zeros((4*D)-1), S)
    append!(EchoFour, dataVec, S)
    EchoFour= EchoFour.*0.1

    finalSound=BaseSound+EchoOne+EchoTwo+EchoThree
    sound(finalSound, S)
    show(length(finalSound))
    return finalSound
end












