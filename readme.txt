%%%%% priming_behav %%%%%
Behavioral experiment at SLAM Lab. Participants engage in a fuzzy speech task using multitalker babble 
stimuli after listening to a "priming" stimuli that consists of regular/irregular/silent/environmental 
baseline rhythm or accelerating/decelerating/constant/silent metronome pulse. This document lists the 
contents of this experiment. 

Author -- Matthew Heard, The Ohio State University, heardmatthew49@gmail.com 

%% Contents
\docs -- Supporting information to the main experiment. 
  \fft_complexstim.png -- Results from a fast Fourier transform (FFT) of the complex rhythm stimuli in 
    this experiment. Note that there are clear peaks at 8 Hz and 16 Hz, but not at 2 Hz or 4 Hz. This
    quantitatively demonstrates the difficult-to-discern pulse of the stimuli. 
  \fft_foreststim.png -- Results from a FFT of the environmental baseline stimuli. Note that there are 
    no strong peaks anywhere that would indicate a presence of rhythm. 
  \fft_simplestim.png -- Results from a FFT of the simple rhythm stimuli. Note that there is a clear
    peak at 4 Hz, as well as 8, 12, and 16 Hz. This demonstrates the strong level of pulse and 8th-note
    subdivision present in the stimuli. 
  \fft_primes.m -- Script that performs a FFT and produced the figures above. 
  \instructions_acceldecel_v1.txt -- Instructions for the priming_accel_decel.m experiment. 
  \instructions_regirreg_v1.txt -- Instructions for the priming_reg_irreg.m experiment. 

\results -- Where results from experiment will save. 

\scripts -- All MATLAB scripts associated with running the experiment. 
  \jp_addnoise_wrapper -- Code used to add multitalker babble to clear sentences. Script modified from 
    https://github.com/jpeelle/jp_matlab. Will require some re-coding to work on another computer as I used
    hard paths when writing this script. 
  \priming_accel_decel_v1.m -- Experiment which uses accelerating/decelerating/constant/silent pulse as
    priming stimuli. I added documentation to make this code easier to understand. 
  \priming_reg_irreg_v1.m -- Experiment which uses regular/irregular/silent/environmental rhythmic songs as
    priming stimuli. I added documentation to make this code easier to understand. 
  \Speaker_Icon.png -- Icon used to show when sound is playing in the above experiments. 

\stim -- Audio stimuli used in the experiment. 
  \practice -- Holds clear and babble (SNR 0) stimuli used in practice block. 
  \primes_accel_decel -- Holds accelerating/decelerating/constant/silent primes used in priming_accel_decel.m.
    \raw -- Has raw stimuli which I used to create shortened/RMS normalized stimuli for experiment. 
  \primes_reg_irreg -- Holds regular/irregular/silent/environmental rhythm stimuli used in primes_reg_irreg.m.
    \raw -- Has raw stimuli which I used to create shortened/RMS normalized stimuli for experiment. 
  \sentences -- Holds clear and SNR 0 babble stimuli for use in both experiments. 
  \SNR-2 -- Holds babble SNR -2 stimuli which are not used in any experiments yet. NOTE: If we switch to these
    stimuli then we need to re-normalize all stimuli to a new RMS. 
  \babble_track_330m_mono_44100 -- Babble track used to generate babble sentences. 
  
Environmental prime is "Public Garden" from http://eng.universal-soundbank.com/atmospheres-outdoor.htm 