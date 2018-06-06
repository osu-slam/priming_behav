%% test_sound_level
% Plays sound clip and lets you adjust the volume to each subjects' hearing
% threshold
clc
dir_scripts = pwd;
cd ..
cd stim
cd primes_reg_irreg

forest_sound = dir('*.wav');
[forest_sound, fs] = audioread(forest_sound(2).name); 
forest_sound = [forest_sound, forest_sound]';

try 
    PsychPortAudio('Close'); 
catch
    disp('PsychPortAudio is already closed. Reopening...')
end

InitializePsychSound
AudioDevice = PsychPortAudio('GetDevices', 3); 
pahandle = PsychPortAudio('Open', [], [], [], fs);
disp('PPA is now open.')

try
    PsychPortAudio('FillBuffer', pahandle, forest_sound);
    PsychPortAudio('Start', pahandle);
    disp('Now playing audio clip. Adjust volume on speakers. Press ESC to stop.')
    WaitTill(inf)
catch
    PsychPortAudio('Close');
end