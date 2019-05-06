%% priming_reg_irreg_v3
% Code used to run the priming behavioral experiment. Consists of 8 blocks
% where a prime (regular/irregular rhythm, or environmental/silent
% baseline) is followed by fuzzy speech task using babble speech. To 
% administer, press Run, fill out subject information, and guide the 
% participant through the instructions. Stimuli have already been RMS
% equalized. 
% Author -- Matthew Heard, The Ohio State University:
% heardmatthew49@gmail.com
% 
% CHANGELOG (MM/DD/YY)
% 04/25/18 -- Began coding experiment. -- MH
% 04/27/18 -- Finished coding v1, still need to finalize stim. -- MH
% 05/03/18 -- Finished stimuli, code is complete!
% 06/05/18 -- Changed instructions and tutorials. Started V2 with a
%   different structure to blocks. 
% 06/18/18 -- Updated instructions. 
% 06/20/18 -- Fixing bug in counterbalancing. 
% 08/28/18 -- Pilot data (n = 15) is collected, not seeing expected trends.
%   Made the following changes:
%   1)  New priming stimuli based on (Przybylski et al., 2013). 
%   2)  Changed from 8 to 6 events per block to save time. 
%   3)  New practice stimuli. 
%   4)  Changed how stimuli is pathed, updated stimuli loading to reflect
%       this. 
%   5)  Added SNR -4 stimuli. 
%   6)  Added new parameter to more easily facilitate switching between
%       stimuli of different SNR. 
% 09/11/18 -- Updated stimuli from silence to pure tone based on average
%   frequency of the ambiance condition (389.365 Hz). Pitch was found using
%   Audacity Nyquist prompt. Also updated counterbalancing. Still works on
%   an A/B paradigm, but now sentences are counterbalanced differently. 
% 05/06/19 -- New stimuli for main task. We found no significant results 
%   using the multitalker babble and have switched to a new set of stimuli.
%   Stimuli were created using Google's Text To Speech (see more here: 
%   https://cloud.google.com/text-to-speech/), and then manipulated to have
%   precise 4 Hz speech rates using both Praat and Matlab. Feel free to 
%   reach out to me with more questions. Vocoding was generated using
%   JPeelle's set of Matlab extensions. Based on some of our previous work,
%   we've found 15ch and 2ch to be sufficient. 

sca; DisableKeysForKbCheck([]); KbQueueStop; clc;
clearvars;

try 
    PsychPortAudio('Close'); 
catch
    disp('PsychPortAudio is already closed.')
end

InitializePsychSound
AudioDevice = PsychPortAudio('GetDevices'); 

%% Collect subject information
prompt = { ...
    'Subject Number:', ...
    'Subject Set (A or B):', ...
    'Skip Tutorial (1 to skip):', ...
    };
dlg_in = inputdlg(prompt);

subj.num   = str2double(dlg_in{1});
subj.set   = upper(dlg_in{2});
NoTutorial = str2double(dlg_in{3});
if NoTutorial ~= 1
    NoTutorial = 0;
end

%% Set parameters
textSize = 50; % Change this to change size of text. 

p.blocks = 8; % number of blocks. 
% NOTE: If p.blocks changes from an even number, double-check generate_keys
% as it will break. I added a test to ensure that p.blocks is an even 
% number before executing the function. 

p.repPrimesPerExp = 2; % primes per block
% NOTE: IF p.repPrimesPerExp changes from 2, double-check 
% generate_keys as I hard-coded the number of comparisons per block. I 
% added a test to ensure that p.repPrimesPerExp is 2.

p.stimPerBlock = 6; % number of sentences in each block
p.stimPerExp = p.blocks * p.stimPerBlock;
p.numSent = 48; % number of sentence structures
p.numStim = 384; % number of sentence .wav files
p.sentType = 8;

p.whichStim = {'sentences_15ch'; 'sentences_24ch'}; 
p.whichPract = {'practice_15ch'; 'practice_24ch'}; 
% Reach out to me if you would like to change stimuli. I am trying to make
% the GitHub package a little smaller. 

t.rxnWindow = 5; % Length of reaction time window after stimuli
% NOTE: If this changes from 5 seconds, change the instructions accordingly

%% Pathing and output file names
dir_scripts = pwd;
cd ..
dir_exp  = pwd;
dir_docs = fullfile(pwd, 'docs');
dir_results = fullfile(pwd, 'results');
dir_stim = fullfile(pwd, 'stim'); 
dir_stim_primes = fullfile(pwd, 'stim', 'primes_reg_irreg');
dir_stim_pract  = fullfile(pwd, 'stim', 'practice');

% A quick bit of sanitation to make it easier to find subject data based on
% subject number... 
if subj.num < 10
    results_tag = ['00' num2str(subj.num) '_priming_reg_irreg_08blocks_' date];
elseif subj.num < 100
    results_tag = ['0' num2str(subj.num) '_priming_reg_irreg_08blocks_' date];
elseif subj.num < 1000
    results_tag = [num2str(subj.num) '_priming_reg_irreg_08blocks_' date];
else
    err('Files will not save with correct name. Check subject number')
end

results_xls = fullfile(dir_results, [results_tag, '.xlsx']);
results_mat = fullfile(dir_results, [results_tag, '.mat']);
results_all = fullfile(dir_results, [results_tag '_allvars.mat']);
results_crash = fullfile(dir_results, [results_tag '_crash.mat']);

% Prevent overwrite of previous data by checking for existing results files
cd(dir_results) 
files = dir(results_mat); % Checks if any files share a name
if ~isempty(files)
    results_tag = [results_tag '_run' num2str(length(files)+1)];
    results_xls = fullfile(dir_results, [results_tag, '.xlsx']);
    results_mat = fullfile(dir_results, [results_tag, '.mat']);
end
cd(dir_exp)

%% Generate keys
% TEST -- double checks parameters which, if changed from default, causes
% errors in the code. 
if p.repPrimesPerExp ~= 2
    error('p.repPrimesPerExp is no longer 2, check counterbalancing!')
elseif mod(p.blocks, 2) ~= 0
    error('p.blocks is not an even number, check counterbalancing!')
elseif p.stimPerBlock ~= 6
    error('p.stimPerBlock is no longer 6, check counterbalancing!')
end

% key_primes and key_sentences - order of primes and sentences
load(fullfile(dir_stim, 'key_counterbalance_v5.mat'))
[key_primes, key_sent, key_pract] = generate_keys(subj, p, key_A);
sentencecheck(key_sent, p)
% For the sake of readability I moved all of this code into functions
% which are specified at the end of this document. 
% NOTE: Instructions has one practice block which draws from 4 sentences.
% If the number of sentences is changed, the code will break. 

% key_answer - the correct answer for each trial
key_answer = mod(key_sent-1, p.sentType);
key_pract_answer = mod(key_pract-1, p.sentType);
% Taking the modulus base 8 of key_sentences-1 gives a vector which 
% corresponds to the correct answer of each trial because there are 8 
% different sentences types. Participants will press the left arrow key for
% female and right arrow key for male. key_direction saves the same 
% information using 'left' and 'right' instead of numbers. 
% NOTE - I included the -1 term above so that the values of key_answer are
% identical to the generate_keys function. For example, sentence 32 is a 
% SM_clear sentence, but mod(32, 8) = 0. However, mod(32-1, 8) = 7. 
% 0 -- OF clear
% 1 -- OF babble
% 2 -- OM clear
% 3 -- OM babble
% 4 -- SF clear
% 5 -- SF babble
% 6 -- SM clear
% 7 -- SM babble
key_direction = cell(1, length(key_answer));
for ii = 1:length(key_answer)
    if any(key_answer(ii) == [0, 1, 4, 5]) % For all "female" trials...
        key_direction{ii} = 'left';
    elseif any(key_answer(ii) == [2, 3, 6, 7]) % For all "male" trials...
        key_direction{ii} = 'right';
    end
    
end

key_pract_direction = cell(1, length(key_pract));
for ii = 1:length(key_pract)
    if any(key_pract_answer(ii) == [0, 1, 4, 5]) % For all "female" trials...
        key_pract_direction{ii} = 'left';
    elseif any(key_pract_answer(ii) == [2, 3, 6, 7]) % For all "male" trials...
        key_pract_direction{ii} = 'right';
    end
    
end

%% Load stimuli into Matlab
% Same as preallocating variables, loading stimuli into Matlab before
% running the code helps keep Matlab's timing accurate. 
% SENTENCES
% TEST -- are you using two groups of stimuli?
if length(p.whichStim) ~= 2
    error('p.whichStim is not size 2!')
end

stim_sent  = cell(2, 1); 
audio_sent = cell(p.stimPerExp*4, 1);
dur_sent   =  nan(p.stimPerExp*4, 1);

% By changing how stimuli are saved, I had to re-code how stimuli are
% loaded. Now by specifying p.whichStim are to be used, you can change
% which stimuli are used in the experiment. In order to preserve the same
% "staggered" (i.e. clear/SNR X/clear/SNR X...) pattern the stimuli were
% loading in before the changes, I had to use both a for loop (jj = 1:2)
% and index (idx = jj, idx = idx + 2). 

for jj = 1:2
    thisstim = p.whichStim{jj};
    cd(dir_stim); cd(thisstim)
    stim_sent{jj} = dir('*.wav'); 
    
    fs = nan(1, length(stim_sent{jj}));
    info_sent(length(stim_sent{jj})) = audioinfo(stim_sent{jj}(end).name); %#ok<SAGROW> % Preallocate structure size
    
    idx = jj; 
    for ii = 1:length(stim_sent{jj})
        [thisdata, fs(ii)] = audioread(stim_sent{jj}(ii).name);
        audio_sent{idx} = [thisdata, thisdata]';
        info_sent(ii)   = audioinfo(stim_sent{jj}(ii).name); 
        dur_sent(idx)   = info_sent(ii).Duration;
        idx = idx + 2;
        % The index is first set to 1 or 2. By incrementing by 2, we ensure
        % that we select every odd or even element of the vector or cell!
    end
    
    % TEST -- are the sampling rates of sentence stimuli the same? Code will not
    % run correctly if not true
    if length(unique(fs)) ~= 1
        error('Check sampling rate of sentences, not equal')
    else
        fs = fs(1);
    end

end

% PRIMES
cd(dir_stim_primes)
stim_primes  = dir('*.wav');
audio_primes = cell(1, length(stim_primes));
dur_primes   = nan(1, length(stim_primes));
fs           = horzcat(nan(1, length(stim_primes)), fs);
info_primes(length(stim_primes)) = audioinfo(stim_primes(end).name); % Preallocate structure size

for ii = 1:length(stim_primes)
    thisfile = fullfile(stim_primes(ii).folder, stim_primes(ii).name);
    [thisdata, fs(ii)] = audioread(thisfile);
    audio_primes{ii}   = [thisdata, thisdata]';
    info_primes(ii)    = audioinfo(thisfile); 
    dur_primes(ii)     = info_primes(ii).Duration;
end

% PRACTICE
stim_pract  = cell(2, 1); 
audio_pract = cell(64, 1);
dur_pract   =  nan(64, 1);

% By changing how stimuli are saved, I had to re-code how stimuli are
% loaded. Now by specifying p.whichStim are to be used, you can change
% which stimuli are used in the experiment. In order to preserve the same
% "staggered" (i.e. clear/SNR X/clear/SNR X...) pattern the stimuli were
% loading in before the changes, I had to use both a for loop (jj = 1:2)
% and index (idx = jj, idx = idx + 2). 

for jj = 1:2
    thispract = p.whichPract{jj};
    cd(dir_stim); cd(thispract)
    stim_pract{jj} = dir('*.wav'); 
    
    fs = nan(1, length(stim_pract{jj}));
    info_pract(length(stim_pract{jj})) = audioinfo(stim_pract{jj}(end).name); % Preallocate structure size
    
    idx = jj; 
    for ii = 1:length(stim_pract{jj})
        [thisdata, fs(ii)] = audioread(stim_pract{jj}(ii).name);
        audio_pract{idx} = [thisdata, thisdata]';
        info_pract(ii)   = audioinfo(stim_pract{jj}(ii).name); 
        dur_pract(idx)   = info_pract(ii).Duration;
        idx = idx + 2;
        % The index is first set to 1 or 2. By incrementing by 2, we ensure
        % that we select every odd or even element of the vector or cell!
    end
    
    % TEST -- are the sampling rates of sentence stimuli the same? Code will not
    % run correctly if not true
    if length(unique(fs)) ~= 1
        error('Check sampling rate of sentences, not equal')
    else
        fs = fs(1);
    end

end

% TEST -- are the sampling rates of prime stimuli the same as the sampling
% rate of the sentences? Code will not run correctly if not true. 
if length(unique(fs)) ~= 1
    error('Check sampling rate of primes and sentences, not equal')
else
    fs = fs(1);
end

% SPEAKER ICON AND FIXATION CROSS
speaker_mat = imread(fullfile(dir_scripts, 'Speaker_Icon.png'));
crossCoords = [-30, 30, 0, 0; 0, 0, -30, 30]; 

cd(dir_exp)

%% Open PsychToolbox (PTB) and RTBox
% PTB is used to generate the screen which the participant will see, and to
% present the auditory stimuli. If anyone is interested in learning to use 
% this incredibly powerful toolbox, I highly recommend checking out these 
% tutorials: http://peterscarfe.com/ptbtutorials.html
[wPtr, rect] = Screen('OpenWindow', 0, 0);
DrawFormattedText(wPtr, 'Please wait...', [], [], 255);
Screen('Flip', wPtr);
centerX = rect(3)/2;
centerY = rect(4)/2;
HideCursor(); 
Screen('TextSize', wPtr, textSize);

pahandle = PsychPortAudio('Open', [], [], [], fs);

% RTBox is used to collect subject response and maintain timing of the
% experiment. It was originally designed for use in MRI, but I prefer to
% use it in behavioral experiments as well. There are very few tutorials
% online, so I recommend reading RTBox.m and RTBoxdemo.m 
RTBox('fake', 1);
RTBox('UntilTimeout', 1);
RTBox('ButtonNames', {'left', 'right', 'space', '4'});

% I convert the speaker image matrix into a texture at this point so the
% experiment runs faster. 
speaker_tex = Screen('MakeTexture', wPtr, speaker_mat);

%% Finish preparing for experiment, run instructions
if ~NoTutorial
% Read in each line of instructions
    inst_file = fullfile(dir_docs, 'instructions_regirreg_08blocks_v2.txt');
    fid = fopen(inst_file);
    ii = 1;
    while 1
        line = fgetl(fid);
        if line == -1
            break
        end

        inst_lines{ii} = line; %#ok<SAGROW>
        ii = ii + 1;
    end

    fclose(fid);
    inst_lines = inst_lines';

    % The tutorial
    noClear = [0 0 0 1 0 1 0 0 1 0 1 0 0 1 0 1 0 0 0 0 0];
    for ii = 1:19
        if any(ii == [5, 7, 10, 12, 15, 17])
            DrawFormattedText(wPtr, inst_lines{ii}, 'center', centerY + 200, 255);
        else
            DrawFormattedText(wPtr, inst_lines{ii}, 'center', 'center', 255);
        end

        Screen('Flip', wPtr, [], noClear(ii));
        WaitSecs(0.5);

        if ii == 5
            PsychPortAudio('FillBuffer', pahandle, audio_pract{7});
            PsychPortAudio('Start', pahandle);
        elseif ii == 7
            PsychPortAudio('FillBuffer', pahandle, audio_pract{8});
            PsychPortAudio('Start', pahandle);
        elseif ii == 9
            PsychPortAudio('FillBuffer', pahandle, audio_pract{7});
            PsychPortAudio('Start', pahandle);
        elseif ii == 11
            PsychPortAudio('FillBuffer', pahandle, audio_pract{6});
            PsychPortAudio('Start', pahandle);
        elseif ii == 14
            PsychPortAudio('FillBuffer', pahandle, audio_pract{17});
            PsychPortAudio('Start', pahandle);
        elseif ii == 16
            PsychPortAudio('FillBuffer', pahandle, audio_pract{20});
            PsychPortAudio('Start', pahandle);
        end

        RTBox('Clear');
        RTBox(inf);
    end

    Screen('Flip', wPtr);
    answer = cell(1, p.stimPerBlock); 

    % Practice block
    while 1
        correct = 0;

        % Present practice prime (environmental sounds)
        DrawFormattedText(wPtr, 'You will now hear ambiance.\nPlease stare at the icon\nin the center of the screen.', 'center', 'center', 255);
        Screen('Flip', wPtr);

        primeStartTarget = GetSecs() + 4; % Start trial 4 seconds from now. 
        % These extra 4 second lets PTB fill the buffer, mark the end of 
        % the stimuli, start the KbQueue
        primeEnd = primeStartTarget + dur_primes(3);

        PsychPortAudio('FillBuffer', pahandle, audio_primes{3});
        PsychPortAudio('Start', pahandle, [], primeStartTarget, 1);
        Screen('DrawTexture', wPtr, speaker_tex);
        Screen('Flip', wPtr);
        WaitTill(primeEnd);

        DrawFormattedText(wPtr, '!!!', 'center', 'center', 255);
        Screen('Flip', wPtr);
        WaitTill(GetSecs() + 0.5);

        for evt = 1:p.stimPerBlock
            WaitTill(GetSecs() + 0.5);
            Screen('DrawLines', wPtr, crossCoords, 2, 255, [centerX, centerY]);
            Screen('Flip', wPtr); 

            stimEnd = GetSecs() + dur_pract(key_pract(evt));
            PsychPortAudio('FillBuffer', pahandle, audio_pract{key_pract(evt)});
            PsychPortAudio('Start', pahandle);

            WaitTill(stimEnd + 0.1); 

            DrawFormattedText(wPtr, 'female', centerX - 500, 'center', 255);
            DrawFormattedText(wPtr, 'male', centerX + 500, 'center', 255);
            Screen('Flip', wPtr);

            RTBox('Clear'); 
            windowStart = GetSecs();
            [~, answer{evt}] = RTBox(windowStart + 5); 

            if strcmp('', answer{evt}) % If subject timed out
                DrawFormattedText(wPtr, 'Too slow! Be sure to respond quicker.', 'center', 'center', 255);
            elseif strcmp(key_pract_direction{evt}, answer{evt}) % If correct
                correct = correct + 1;
                DrawFormattedText(wPtr, 'You are correct! Good job!', 'center', 'center', 255);
            else % If wrong
                DrawFormattedText(wPtr, 'Oops, wrong answer!', 'center', 'center', 255);
            end

            Screen('Flip', wPtr);
            WaitTill(GetSecs() + 1);
            Screen('Flip', wPtr);
        end

        % Feedback
        correct_trials = sprintf(inst_lines{20}, num2str(correct));
        DrawFormattedText(wPtr, correct_trials, 'center', 'center', 255);
        Screen('Flip', wPtr);

        WaitSecs(0.5);
        RTBox('Clear');
        [~, cont] = RTBox(inf);
        if strcmp(cont, 'space')
            DrawFormattedText(wPtr, inst_lines{21}, 'center', 'center', 255);
            Screen('Flip', wPtr);
            WaitTill(GetSecs + 0.5);
            RTBox('Clear');
            RTBox(inf);
            % To prevent the practice condition from interfering with the
            % rest of the experiment, I've inserted a 20 second break where
            % the experiment is "loading". 
            DrawFormattedText(wPtr, 'Please wait...', 'center', 'center', 255);
            Screen('Flip', wPtr);
            WaitTill(GetSecs() + 20);
            break
        else
            Screen('Flip', wPtr);
        end

    end

end

DrawFormattedText(wPtr, 'Press space to begin.', 'center', 'center', 255);
Screen('Flip', wPtr);
RTBox('Clear');
RTBox(inf);

%% ACTUAL EXPERIMENT %% 
% Preallocating variables
answer = cell(1, p.numSent);
resp = nan(1, p.numSent);
eventEnd = nan(1, p.numSent);
evt = 1; % Index will increase after each trial

try
    for blk = 1:p.blocks
        %% Present prime
        DrawFormattedText(wPtr, '!!!', 'center', 'center', 255);
        Screen('Flip', wPtr);
        WaitTill(GetSecs() + 1); 
        Screen('DrawTexture', wPtr, speaker_tex);
        Screen('Flip', wPtr);
        primeEnd = GetSecs() + dur_primes(key_primes(blk));
        PsychPortAudio('FillBuffer', pahandle, audio_primes{key_primes(blk)});
        PsychPortAudio('Start', pahandle);

        WaitTill(primeEnd + 0.1); 
        Screen('Flip', wPtr);
        WaitTill(GetSecs() + 0.5);
        
        %% Present sentences
        for ii = 1:p.stimPerBlock
            WaitTill(GetSecs() + 0.5);
            Screen('DrawLines', wPtr, crossCoords, 2, 255, [centerX, centerY]);
            Screen('Flip', wPtr); 

            stimEnd = GetSecs() + dur_sent(key_sent(evt));
            PsychPortAudio('FillBuffer', pahandle, audio_sent{key_sent(evt)});
            PsychPortAudio('Start', pahandle);

            WaitTill(stimEnd + 0.1); 

            %% Collect response
            DrawFormattedText(wPtr, 'female', centerX - 500, 'center', 255);
            DrawFormattedText(wPtr, 'male', centerX + 500, 'center', 255);
            % To make sure timing is accurate, run as little code between
            % when the participant can respond and the response is
            % collected. Said window begins with this command:  
            eventEnd(evt) = Screen('Flip', wPtr);

            RTBox('Clear'); 
            [thisresp, answer{evt}] = RTBox(GetSecs() + 5); 
            if isempty(thisresp) % Stop bug if subject times out
                resp(evt) = inf; 
            else
                resp(evt) = thisresp;
            end
            
            Screen('Flip', wPtr);
            WaitTill(GetSecs() + 0.5);
            Screen('Flip', wPtr);
            
            evt = evt + 1;
        end

    end
    
    % End of experiment
    DrawFormattedText(wPtr, 'End of experiment.\nThanks for participating!', 'center', 'center', 255);
    Screen('Flip', wPtr);
    WaitSecs(4);

catch err
% Note that the entire experiment is written between a try/catch loop. This
% prevents the experiment from not saving data when it encounters an error.
% Note that pressing escape during the experiment to quit causes RTBox to 
% throw an error. 
sca
PsychPortAudio('Close');
save(results_crash);
rethrow(err)
    
end


%% Close the experiment and save data
% If the experiment does not encounter any errors, then this section is
% responsible for saving the output. 
sca
PsychPortAudio('Close');

rt = resp - eventEnd;
data_cell = cell(p.numSent + 1, 7);
data_mat  = nan(p.numSent, 7);

% This is the format for the columns of data_cell and data_mat. 
data_cell{1, 1} = 'Prime';
data_cell{1, 2} = 'Sentence';
data_cell{1, 3} = 'Obj/Subj';
data_cell{1, 4} = 'Clear/Babble';
data_cell{1, 5} = 'Subject response';
data_cell{1, 6} = 'Correct?';
data_cell{1, 7} = 'Reaction time'; % Is inf if subject timed out
% However, data_mat uses numbers instead of strings when representing data.
% These numbers mirror the alphabetical order of the stimuli as they are 
% named and are as follow:
% PRIME        -- 1:environment baseline
%                 2:complex rhythm
%                 3:silent baseline
%                 4:simple rhythm
% SENTENCE     -- Each number corresponds to the sentence structure of that
%                 event (i.e. 1 through 64)
% OBJ/SUBJ     -- 1:OR sentence
%                 2:SR sentence
% CLEAR/BABBLE -- 1:Babble sentence (filenames end with a number)
%                 2:Clear sentence
% SUBJ RESP    -- 0:No response/subject timed out
%                 1:Left
%                 2:Right
% CORRECT      -- 0:Wrong answer
%                 1:Right answer
% RT           -- Reaction time (in seconds) relative to end of stimulus.
%                 Inf represents that subject timed out. 

idx = 1;
for ii = 1:p.stimPerBlock:p.numSent
    data_cell{ii+1, 1} = stim_primes(key_primes(idx)).name;
    data_mat(ii:ii+p.stimPerBlock-1, 1) = key_primes(idx);
    idx = idx + 1;
end

sent_idx = ceil(key_sent/2);
% Since stimuli are saved in two separate folders, we have to use this
% sent_idx to access them. Basically, it corresponds to the stimuli number
% in each folder of stimuli. 

for ii = 1:p.numSent
    if mod(key_sent(ii), 2) == 0 % if key_sent(ii) is even/babble trial
        whichSet = 2;
    else % if key_sent(ii) is odd/clear trial
        whichSet = 1;
    end

    thissent = stim_sent{whichSet}(sent_idx(ii)).name;

    data_cell{ii+1, 2} = thissent;
    data_mat(ii, 2)    = str2double(thissent(1:3));
    data_cell{ii+1, 3} = thissent(4);
    if strcmp(thissent(4), 'O') % OR sentences
        data_mat(ii, 3) = 1;
    elseif strcmp(thissent(4), 'S') % SR sentences
        data_mat(ii, 3) = 2;
    end

    clearbab = thissent(7:end);
    clearbab = strsplit(clearbab, '.');
    data_cell{ii+1, 4} = clearbab{1};
    if strcmp(clearbab{1}, 'c') % Clear sentences
        data_mat(ii, 4) = 2; 
    else % Babble sentences, of any SNR
        data_mat(ii, 4) = 1; 
    end

    data_cell{ii+1, 5} = answer{ii};
    if strcmp(answer{ii}, 'left') % Subject responded 'left'
        data_mat(ii, 5) = 2; 
    elseif strcmp(answer{ii}, 'right') % Subject responded 'right'
        data_mat(ii, 5) = 1; 
    elseif isempty(answer{ii}) % Subject timed out
        data_mat(ii, 5) = 0; 
    end

    if strcmp(answer{ii}, key_direction{ii}) % if right answer
        data_cell{ii+1, 6} = 1;
        data_mat(ii, 6) = 1;
    else
        data_cell{ii+1, 6} = 0;
        data_mat(ii, 6) = 0;
    end

    if isinf(rt(ii)) % if subject timed out
        data_cell{ii+1, 7} = 'Inf';
    else
        data_cell{ii+1, 7} = rt(ii);
    end
    
    data_mat(ii, 7) = rt(ii);

end

% Save as .xls for easy reading
xlswrite(results_xls, data_cell);

% Save as .mat for easy analysis
save(results_mat, 'data_mat');

% OPTIONAL - Save all variables for subject just in case you need them
% save(results_all);

%% Supporting functions
% Here are all of the functions I wrote for this experiment. Keeping them
% down here makes the code more readable and cuts down on the number of
% variables produced by the script. 

function [key_primes, key_sent, key_pract] = generate_keys(subj, p, key_A)
% Output 
% key_primes: key containing counterbalanced order of primes. 
% key_sent: key containing counterbalanced order of sentences. 
% key_pract: key containing order of sentences for practice. 

% COUNTERBALANCE ORDER OF PRIMES
% Participants can be a member of set A or set B. Set A starts with a
% rhythm block (i.e. regular or irregular prime) and alternates with 
% baseline blocks (i.e. environmental or silent prime). Set B starts with a
% baseline block and alternates with rhythm blocks. Alternating rhythm and
% baseline blocks ensures that there are no contamination effects from
% repeating rhythm blocks. The first row represents the type of prime, and
% the second row helps counterbalance clear/babble and OR/SR, described 
% below. 
key_primes = nan(1, p.blocks);
babble_clear = nan(1, p.blocks);
cb_irr_reg = Shuffle([1 1 2 2; 0 1 0 1], 1);
cb_env_sil = Shuffle([3 3 4 4; 0 1 0 1], 1);
% 1 - Ambient prime
% 2 - Slow prime
% 3 - Medium prime
% 4 - Fast prime

% Set the first block as rhythm or baseline depending on whether subject is
% in set A or set B
if strcmp(subj.set, 'A')
    for ii = 1:p.blocks/2
        key_primes(2*ii-1) = cb_irr_reg(1, ii);
        key_primes(2*ii)   = cb_env_sil(1, ii);
        babble_clear(2*ii-1)  = cb_irr_reg(2, ii);
        babble_clear(2*ii)    = cb_env_sil(2, ii);
%         % Note that 2*ii-1 indicates the odd-numbered blocks (1, 3, 5, 7), 
%         % whereas 2*ii indicates the even-numbered blocks (2, 4, 6, 8). I
%         % use this trick because there is a dimension mismatch between
%         % cb_reg_irr (4-element vector), cb_env_sil (4-element vector, and 
%         % cb_all (8-element vector). which_row is used to counterbalance
%         % OR/SR and clear/babble. 
    end
    
elseif strcmp(subj.set, 'B')
    for ii = 1:p.blocks/2
        key_primes(2*ii-1) = cb_env_sil(1, ii);
        key_primes(2*ii)   = cb_irr_reg(1, ii);
        babble_clear(2*ii-1)  = cb_env_sil(2, ii);
        babble_clear(2*ii)    = cb_irr_reg(2, ii);
    end
    
end

% COUNTERBALANCE BABBLE/CLEAR AND OR/SR
% To control for the effect of the decay of priming effect, the order of
% sentence presentation has to be rigorously counterbalanced. However,
% since there are four main conditions of each sentence (OR_clear,
% SR_clear, OR_babble, SR_babble) and only six sentences per block, we
% decided to have each run be entirely babble or clear, and to just shuffle
% the OR/SR order per subject. I pre-counterbalanced accordingly and saved
% them in the file key_counterbalance_v5.mat, which contains variables 
% key_A. This file is used to counterbalance the order of stimuli and has 
% been balanced. 
% The vector called which_row from earlier shuffles the order of 
% presentation of each counterbalanced block. For better visualization, see
% counterbalance_v5.xlsx in the \docs folder. Note that the numbers in each
% element of key_A may seem arbitrary. I promise, it will make sense in the 
% end, but the organization is as follows:
% 0 -- Object-relative 
% 4 -- Subject-relative
% Later on in the code, I add a carefully balanced vector of zeros and twos
% to represent the shuffled male/female conditions. 
key_bc = repmat(babble_clear', [1 6]);

key_os = nan(p.blocks, p.stimPerBlock);
which_row = Shuffle(1:8);
os = key_A; % COUNTERBALANCE OR/SR
for ii = 1:length(key_primes)
    key_os(ii, :) = os(which_row(ii), :);
end
% The above loop transforms the matrix bc_os (which is either key_A or
% key_B depending on the subject) from its organized form to its shuffled
% form. 

key_os = reshape(key_os', [1, p.numSent]);
key_bc = reshape(key_bc', [1, p.numSent]);

% SHUFFLE ORDER OF SENTENCE STRUCTURES
% Each sentence structure (e.g. ___ who kiss ___ are happy) has four
% constructions (Object-relative Male (OM), Object-relative Female (OF),
% Subject-relative Male (SM), Subject-relative Female (SF)) under two
% auditory conditions (clear and babble). Therefore, there are 4x2 = 8
% different sentences for each structure. These can be indexed by the 
% following vector, which is shuffled across all trials:
key_structures = Shuffle(1:8:p.numStim);

% COUNTERBALANCE MALE/FEMALE
% Although this manipulation is present only to distract subjects from the
% OR/SR component of the task, it cannot be counterbalanced across every
% block--we are counterbalancing OR/SR and clear/babble, which means we 
% must control 4 stimuli per block. If we controlled M/F, we would have to 
% control for 8 stimuli. 12/4 is an interger, while 12/8 is not. So we
% randomize the number of male and female trials to really throw subjects
% off. 
key_fem_male = 2*randi([0 1], [1, 48]);
% for ii = 1:p.stimPerBlock:p.numSent
%     % Randomly shuffle the first three trials...
%     temp = Shuffle([0 0 0 1 1 1]); 
%     first_three_fm = temp(1:3); 
%     
%     % Determine what the last three trials must be so that the entire block
%     % is counterbalanced
%     last_three_fm  = nan(1, 3);
%     first_three_cb_os = key_bc_os(ii:ii+2);
%     last_three_cb_os  = key_bc_os(ii+3:ii+5); 
%     for jj = 1:3
%         last_three_fm(first_three_cb_os(jj) == last_three_cb_os) = ~first_three_fm(jj);        
%     end
% 
%     % Convert from logicals (1s and 0s) to 2s and 0s. I swear, this makes
%     % sense in the end...
%     key_fem_male(ii:ii+2)   = 2*first_three_fm; 
%     key_fem_male(ii+3:ii+5) = 2*last_three_fm; 
%     
% end

key_events = key_os + key_fem_male + key_bc; 

% COUNTERBALANCE SENTENCES 
% In summary, I have counterbalanced the order sentences according to 
% babble/clear and OR/SR (0, 1, 4, 5) as well as female/male (0, 2). By 
% adding all of these keys together, we get the order of events 
% (key_events) for the experiment. Adding this to the order of sentence 
% structures gives rise to key_sent, the order of stimuli for this 
% experiment. 
% O/S + M/F + C/B = # -- Event
%  0  +  0  +  0  = 0 -- OF clear
%  0  +  0  +  1  = 1 -- OF babble
%  0  +  2  +  0  = 2 -- OM clear
%  0  +  2  +  1  = 3 -- OM babble
%  4  +  0  +  0  = 4 -- SF clear
%  4  +  0  +  1  = 5 -- SF babble
%  4  +  2  +  0  = 6 -- SM clear
%  4  +  2  +  1  = 7 -- SM babble
key_sent = key_events + key_structures;

% PRACTICE KEY
% Creates one block for practice. Can choose from 8 sentence structures 
% 6 trials, so generating key is a little different. 
key_pract = Shuffle(1:8:64); key_pract = key_pract(1:6);
key_pract_orsr = Shuffle(0:7); key_pract_orsr = key_pract_orsr(1:6); 
key_pract = key_pract + key_pract_orsr;
    
end

function sentencecheck(key_sentences, p)
% This function throws an error if there is a problem with the sentences 
% key. It counts the number of object- and subject-relative, male and 
% female, clear and babble sentences and makes sure they are all equal. 
% Then, it makes sure that each block of sentences have one of each 
% category. 
obj    = [];
sub   = [];
% fem    = [];
% male   = [];
ch15  = [];
ch24 = [];

key_obj    = sort(horzcat(1:8:p.numStim, 2:8:p.numStim, 3:8:p.numStim, 4:8:p.numStim)); 
key_subj   = sort(horzcat(5:8:p.numStim, 6:8:p.numStim, 7:8:p.numStim, 8:8:p.numStim)); 
% key_fem    = sort(horzcat(1:8:p.numStim, 2:8:p.numStim, 5:8:p.numStim, 6:8:p.numStim));
% key_male   = sort(horzcat(3:8:p.numStim, 4:8:p.numStim, 7:8:p.numStim, 8:8:p.numStim));
key_ch15  = (1:2:p.numStim);
key_ch24 = (2:2:p.numStim);

% Pull out which sentences are male/fem, obj/subj, clear/babble
for ii = 1:length(key_sentences)
    if find(key_sentences(ii) == key_obj)
        obj = horzcat(obj, key_sentences(ii));  %#ok<AGROW>
    elseif find(key_sentences(ii) == key_subj) 
        sub = horzcat(sub, key_sentences(ii));  %#ok<AGROW>
    end
    
%     if find(key_sentences(ii) == key_fem)
%         fem = horzcat(fem, key_sentences(ii));  %#ok<AGROW>
%     elseif find(key_sentences(ii) == key_male)
%         male = horzcat(male, key_sentences(ii));  %#ok<AGROW>
%     end
    
    if find(key_sentences(ii) == key_ch15)
        ch15 = horzcat(ch15, key_sentences(ii));  %#ok<AGROW>
    elseif find(key_sentences(ii) == key_ch24)
        ch24 = horzcat(ch24, key_sentences(ii));  %#ok<AGROW>
    end
end

% TEST - does each category have the same number of sentences?
if (length(obj) ~= length (sub))
    error('sentencecheck: Number of object and subject-relative stim not equal')    
% elseif (length(fem) ~= length (male))
% 	error('sentencecheck: Number of female and male stim not equal')
elseif (length(ch24) ~= length (ch15))
    error('sentencecheck: Number of babble and clear stim not equal')
end

% Check evert two blocks of sentences for balance
% Code is busted now that we're using different counterbalance?
% block = 1;
% for ii = 1:2*p.stimPerBlock:length(key_sentences)
%     temp = key_sentences(ii:ii+2*p.stimPerBlock-1); temp = sort(mod(temp, 8));
%     if sum(ismember((0:7), temp)) < 4
%         error(['sentencecheck: blocks ' num2str(block) ' and ' num2str(block+1) ' does not have one of each stim type'])
%     end
%     block = block + 2;
% end

end
