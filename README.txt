DYNANOTE
By: Team Trombones
------------------
INSTRUCTIONS:

*Note that to run the program on your system you most likely will
need to install a few Julia packages. The REPL should give you the 
command needed to install the package(s): Pfg.add("Package")

1. In the Julia REPL, type include("DYNANOTE.jl") to run the program.

*You may recieve various warnings in the terminal when running the 
program. Disregard these as they do not affect the functionality.

2. Running the programn should bring you to the main GUI. This 
GUI various sound modification options.

*The background will be white, which differs from our demonstration
as the image file must be downloaded locally. 

3. To get started, press the record button to record in a sound. 
Currently the sample will < 1 second in duration (Part of the end is cut off
to elminate a clicking noise).

4. Preform various sound modifications as desired. Pressing the "play" button will
play the sound back. Pressing the "clear" button allows you to start over.

*In our prototype, the only modifcations avaliable are sustain (Whole Note, Half Note, and
Quarter Note only), ADSR, Attack-Decay, Reverb, and Tremolo.

5. Once you have made the various modifcations, press the "Generate Synthesizer" button
to create a synthesizer with the sample. This will generate another GUI in which you can 
record and play back an song.

*Please note that in our current prototype, the synthesizer only supports generating add 
synthesizer from an original sample and a sample with Tremolo added to it.

