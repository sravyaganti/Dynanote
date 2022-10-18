using Sound: soundsc, sound
using Plots
using WAV: wavread


# S = 44100

# t = (1:S/2)/S
# data = cos.(2*pi*440*t)




# show(L)
# print("\n")
# show(length(data[1:L-6*D]))
# print("\n")
# show(length(data[1+D:L-5*D]))
# print("\n")
# show(length(data[1+2*D:L-4*D]))
# print("\n")
# show(length(data[1+3*D:L-3*D]))
# print("\n")
# show(length(data[1+4*D:L-2*D]))
# print("\n")
# show(length(data[1+5*D:L-D]))
# print("\n")
# show(length(data[1+6*D:L]))
# print("\n")

# echoOne = data[1:L-6*D]
# lengthEchoOne = length(echoOne)
# zeroes = zeros(L-lengthEchoOne-2)
# append!(totalEchoOne, zeroes, 44100)
# append!(totalEchoOne, echoOne, 44100)

# final=totalEchoOne+data;
# sound(final, 44100)
#+ data[1+D:L-5*D] + data[1+2*D:L-4*D]+ data[1+3*D:L-3*D]+ data[1+4*D:L-2*D]+ data[1+5*D:L-D]+data[1+6*D:L]
# sLength= length(s)
# #l=L=sLength
# soundsc(s, 44100)


S = 44100
# data, S = wavread("piano_note.wav")
# show(length(data))
file = "c:/Users/sravy/.julia/engr100-trombones/piano_note.wav"
(data, S, _, _) = wavread(file)
soundsc(data,S)

L= length(data)
finalEcho = Float32[]
finalEcho = zeros(L)
totalEcho = Float32[]
#show(L)
print("\n")
d= (floor(L/10))
D= trunc(Int, d)

show(D)
echoes=[1,2,3,4]

for index in 1:length(echoes)    
    zeroesPtOne=zeros((index+3)*D);
    echo=data[1:(4*D)]
    local zL
    zl=length(zeroesPtOne)
    local eL
    eL= length(echo)
    zeroesPtTwo=zeros(L-(zl+eL)-3)
    print("\n")
    show(length(zeroesPtTwo))
    empty!(totalEcho)
    append!(totalEcho, zeroesPtOne, 44100)
    append!(totalEcho, echo, 44100)
    append!(totalEcho, zeroesPtTwo, 44100)
    global finalEcho
    finalEcho+=totalEcho
end
show(length(finalEcho))
# soundsc(finalEcho, 44100)

