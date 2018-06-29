%%%%% priming_behav %%%%%
Behavioral experiment at SLAM Lab. Participants engage in a fuzzy speech task using multitalker babble 
stimuli after listening to a "priming" stimuli that consists of regular/irregular/silent/environmental 
baseline rhythm or accelerating/decelerating/constant/silent metronome pulse. This document lists the 
contents of this experiment. 

Author -- Matthew Heard, The Ohio State University, heardmatthew49@gmail.com 

%% Contents
\docs -- Supporting information to the main experiment. 
  \fft_ambiance.png -- Results from a FFT of the environmental baseline stimuli. Note that there are 
    no strong peaks anywhere that would indicate a presence of rhythm. 
  \fft_complex.png -- Results from a fast Fourier transform (FFT) of the complex rhythm stimuli in 
    this experiment. Note that there are clear peaks at 8 Hz and 16 Hz, but not at 2 Hz or 4 Hz. This
    quantitatively demonstrates the difficult-to-discern pulse of the stimuli. 
  \fft_silence.png -- Results from a FFT of the silence stimuli. Note that it is zero.
  \fft_simple.png -- Results from a FFT of the simple rhythm stimuli. Note that there is a clear
    peak at 4 Hz, as well as 8, 12, and 16 Hz. This demonstrates the strong level of pulse and 8th-note
    subdivision present in the stimuli. 
  \fft_primes.m -- Script that performs a FFT and produced the figures above. 
  \instructions_acceldecel.txt -- Instructions for the priming_accel_decel.m experiment. 
  \instructions_regirreg_08blocks.txt -- Instructions for the priming_reg_irreg_08blocks.m experiment. 
  \instructions_regirreg_16blocks.txt -- Instructions for the priming_reg_irreg_16blocks.m experiment. 

\results -- Where results from experiment will save. 
  \placeholder.txt -- A placeholder file used to ensure that this directory generates. Feel free to delete
    after installation!

\scripts -- All MATLAB scripts associated with running the experiment. 
  \priming_accel_decel_v1.m -- Experiment which uses accelerating/decelerating/constant/silent pulse as
    priming stimuli. I added documentation to make this code easier to understand. 
  \priming_reg_irreg_08blocks.m -- Experiment which uses regular/irregular/silent/environmental rhythmic songs as
    priming stimuli. All primes are the same duration and each category is presented twice. Blocks are 8 sentences
    long. I added documentation to make this code easier to understand. 
  \priming_reg_irreg_16blocks.m -- Experiment which uses regular/irregular/silent/environmental rhythmic songs as
    priming stimuli. Primes are either short or long, and each duration and category is presented twice. As such, 
    the blocks use four sentences each. I added documentation to make this code easier to understand. 
  \Speaker_Icon.png -- Icon used to show when sound is playing in the above experiments. 

\stim -- Audio stimuli used in the experiment. 
  \practice -- Holds clear and babble (SNR 0) stimuli used in practice block. 
  \primes_accel_decel -- Holds accelerating/decelerating/constant/silent primes used in priming_accel_decel.m.
  \primes_reg_irreg_08blocks -- Holds regular/irregular/silent/environmental rhythm stimuli used in primes_reg_irreg.m.
    Only one duration of prime (32sec) is used. 
  \primes_reg_irreg_16blocks -- Holds regular/irregular/silent/environmental rhythm stimuli used in primes_reg_irreg.m.
    Each prime has a short (32sec) and long (64sec) version. 
  \sentences -- Holds clear and SNR 0 babble stimuli for use in both experiments. 
  \SNR-0_untrimmed -- Holds babble SNR 0 stimuli that have not been trimmed to contain only speech sound. NOTE: If we 
    switch to these stimuli then we need to re-normalize all stimuli to a new RMS. 
  \SNR-2_untrimmed -- Holds babble SNR -2 stimuli which are not used in any experiments yet. Also have not been trimmed
    NOTE: If we switch to these stimuli then we need to re-normalize all stimuli to a new RMS. 
  \key_counterbalance_v3.mat -- Variables used in primes_reg_irreg_08blocks.m to counterbalance stimuli. 
  
Environmental prime is "Jungle River" from http://eng.universal-soundbank.com/