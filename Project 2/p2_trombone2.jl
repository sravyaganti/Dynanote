using WAV: wavread
using Sound

file = "touch.wav"
(x, S, _, _) = wavread(file)
N = length(x); S = 8192

function transcriber(x::Matrix{Float64})
  
    N = length(x); S = 8192

    freq1 = [697, 770, 852, 941]
    freq2 = [1209, 1336, 1477]

    global phone_number;

    phone_number = String[]
    num_buttons_pressed = length(x) ÷ 4096
    for i in 1:num_buttons_pressed
        N1 = (i-1) * 4096 + 1; N2 = i * 4096;
        temp_x = x[N1:N2] 

        # correlation method that works for any phase shift
        c1 = cos.(2π * freq1 * (1:4096)'/S) * temp_x
        s1 = sin.(2π * freq1 * (1:4096)'/S) * temp_x
        corr1 = s1.^2 + c1.^2
        i1 = argmax(corr1) # "argument that maximizes"
        frequency_1 = (freq1[i1])

        c2 = cos.(2π * freq2 * (1:4096)'/S) * temp_x
        s2 = sin.(2π * freq2 * (1:4096)'/S) * temp_x
        corr2 = s2.^2 + c2.^2
        i2 = argmax(corr2) # "argument that maximizes"
        frequency_2 = (freq2[i2])
    
        # finding proper key pressed based on first and second frequencies found
        row = findfirst(isequal(frequency_1),freq1)
        col = findfirst(isequal(frequency_2),freq2)
        key = (row-1)*3+col

        if key == 10
            push!(phone_number,"*")
        elseif key == 11
            push!(phone_number,"0")
        elseif key == 12
            push!(phone_number,"#")
        else
            push!(phone_number,string(key))
        end

    end
    
    return phone_number
    
end

## calling the function 
transcribe = transcriber(x)
print(join(transcribe))

