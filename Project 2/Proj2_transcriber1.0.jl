using WAV: wavread
using Sound

file = "touch.wav"
(x, S, _, _) = wavread(file)
N = length(x); S = 8192

freq1 = [697, 770, 852, 941]
freq2 = [1209, 1336, 1477]
global phone_number;

phone_number = String[]
num_buttons_pressed = length(x) ÷ 4096
for i in 1:num_buttons_pressed
    N1 = (i-1) * 4096 + 1; N2 = i * 4096;
    temp_x = x[N1:N2] 

    c1 = cos.(2π * freq1 * (1:4096)'/S) * temp_x
    s1 = sin.(2π * freq1 * (1:4096)'/S) * temp_x
    corr1 = s1.^2 + c1.^2
    i1 = argmax(corr1) # "argument that maximizes"
    index_1 = (freq1[i1])
    c2 = cos.(2π * freq2 * (1:4096)'/S) * temp_x
    s2 = sin.(2π * freq2 * (1:4096)'/S) * temp_x
    corr2 = s2.^2 + c2.^2
    i2 = argmax(corr2) # "argument that maximizes"
    index_2 = (freq2[i2])
   
    
    if index_1 == 697 && index_2 == 1209
        push!(phone_number,"1")

    elseif index_1 == 697 && index_2 == 1336
        push!(phone_number,"2")

    elseif index_1 == 697 && index_2 == 1477
        push!(phone_number,"3")

    elseif index_1 == 770 && index_2 ==  1209
        push!(phone_number,"4")

    elseif index_1 == 770 && index_2 == 1336
        push!(phone_number,"5")

    elseif index_1 == 770 && index_2 == 1477
        push!(phone_number,"6")

    elseif index_1 == 852 && index_2 == 1209
        push!(phone_number,"7")

    elseif index_1 == 852 && index_2 == 1336
        push!(phone_number,"8")

    elseif index_1 == 852 && index_2 == 1477
        push!(phone_number,"9")

    elseif index_1 == 941 && index_2 == 1209
        push!(phone_number,"*")

    elseif index_1 == 941 && index_2 == 1336
        push!(phone_number,"0")

    else
        push!(phone_number,"#")
    end

end
for i in 1:length(phone_number)
    print(phone_number[i])
end