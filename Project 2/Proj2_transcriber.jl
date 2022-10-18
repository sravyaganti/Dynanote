using WAV: wavread
using Sound

file = "touch.wav"
(x, S, _, _) = wavread(file)
#x = x-1
@show N = length(x); #S = 8192

freq1 = [697, 770, 852, 941]
freq2 = [941, 1209, 1336]

phone_number = ""
num_buttons_pressed = length(x) ÷ 4096
for i in 1:num_buttons_pressed
    N1 = (i-1)*4096 + 1; N2 = i*4096 +1;
    temp_x = x[N1:N2]

    c1 = cos.(2π * freq1 * (1:4096)'/S) * temp_x
    s1 = sin.(2π * freq1 * (1:4096)'/S) * temp_x
    corr1 = s1.^2 + c1.^2
    i1 = argmax(corr1) # "argument that maximizes"

    c2 = cos.(2π * freq2 * (1:4096)'/S) * temp_x
    s2 = sin.(2π * freq2 * (1:4096)'/S) * temp_x
    corr2 = s2.^2 + c2.^2
    i2 = argmax(corr2) # "argument that maximizes"
    

    if index == 10
        global phone_number += "*"
    elseif index == 11
        global phone_number += "0"
    elseif index == 12
        global phone_number += "#"
    else
        global phone_number += i2 + (i1 .- 1)*3
    end
end
print(phone_number)