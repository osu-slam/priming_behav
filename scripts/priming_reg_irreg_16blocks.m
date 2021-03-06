%% priming_behav_v2
% Code used to run the priming behavioral experiment. Consists of 16 blocks
% where a prime (regular/irregular rhythm, or environmental/silent
% baseline) is followed by fuzzy speech task using babble speech (4 
% trials). Half of the primes are 33 seconds long, while the others are 66 
% seconds long. To administer, press Run, fill out subject information, and
% guide the participant through the instructions. Stimuli have already been
% RMS equalized. 
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

sca; DisableKeysForKbCheck([]); KbQueueStop; clc;
clearvars;

try 
    PsychPortAudio('Close'); 
catch
    disp('PsychPortAudio is already closed.')
end

InitializePsychSound
AudioDevice = PsychPortAudio('GetDevices', 3); 

%% Collect subject information
prompt = { ...
    'Subject Initials:', ...
    'Subject Number:', ...
    'Subject Set (A or B):', ...
    'Skip Tutorial (1 to skip):', ...
    };
dlg_in = inputdlg(prompt);

subj.init  = dlg_in{1};
subj.num   = str2double(dlg_in{2});
subj.set   = upper(dlg_in{3});
NoTutorial = str2double(dlg_in{4});
if NoTutorial ~= 1
    NoTutorial = 0;
end

%% Set parameters
textSize = 50; % Change this to change size of text. 

p.blocks = 16; % Number of blocks. 
% NOTE: If p.blocks changes from an even number, double-check generate_keys
% as it will break. I added a test to ensure that p.blocks is an even 
% number before executing the function. 
% And now, if this changes from 16 this completely breaks counterbalancing
% babble across primes!

p.repPrimesPerExp = 2; % Repeated primes over the experiment.
% NOTE: IF p.repPrimesPerExp changes from 2, double-check 
% generate_keys as I hard-coded the number of comparisons per block. I 
% added a test to ensure that p.repPrimesPerExp is 2.

p.stimPerBlock = 4; % Number of sentences in each block.
p.numSent = 64; % number of sentence structures
p.numStim = 512; % number of sentence .wav files

t.rxnWindow = 5; % Length of reaction time window after stimuli.
% NOTE: If this changes from 5 seconds, change the instructions accordingly

t.whitenoise = 5; % Duration of white noise
vol_wn = 0.2; % Volumen of white noise

%% Pathing and output file names
dir_scripts = pwd;
cd ..
dir_exp  = pwd;
dir_docs = fullfile(pwd, 'docs');
dir_results = fullfile(pwd, 'results');
dir_stim_primes = fullfile(pwd, 'stim', 'primes_reg_irreg_16blocks');
dir_stim_sent   = fullfile(pwd, 'stim', 'sentences');
dir_stim_pract  = fullfile(pwd, 'stim', 'practice');

% A quick bit of sanitation to make it easier to find subject data based on
% subject number... 
if subj.num < 10
    results_tag = ['00' num2str(subj.num) '_' subj.init '_priming_reg_irreg_16blocks_' date];
elseif subj.num < 100
    results_tag = ['0' num2str(subj.num) '_' subj.init '_priming_reg_irreg_16blocks_' date];
elseif subj.num < 1000
    results_tag = [num2str(subj.num) '_' subj.init '_priming_reg_irreg_16blocks_' date];
else
    error('Files will not save with correct name. Check subject number')
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
    results_xls = fullfile(dir_stim_sent, [results_tag, '.xlsx']);
    results_mat = fullfile(dir_stim_sent, [results_tag, '.mat']);
end
cd(dir_exp)

%% Generate keys
% TEST -- double checks parameters which, if changed from default, causes
% errors in the code. 
if p.repPrimesPerExp ~= 2
    error('p.repPrimesPerExp is no longer 2, check counterbalancing!')
elseif mod(p.blocks, 2) ~= 0
    error('p.blocks is not an even number, check counterbalancing!')
end

% key_primes and key_sentences - order of primes and sentences
[key_primes, key_sent, key_pract] = generate_keys(subj, p);
sentencecheck(key_sent, key_primes, p)
% For the sake of readability I moved all of this code into functions
% which are specified at the end of this document. 
% NOTE: Instructions has one practice block which draws from 4 sentences.
% If the number of sentences is changed, the code will break. 

% key_answer - the correct answer for each trial
key_answer = mod(key_sent-1, p.stimPerBlock);
key_pract_answer = mod(key_pract-1, p.stimPerBlock);
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
cd(dir_stim_sent)
stim_sent  = dir('*.wav'); 
audio_sent = cell(1, length(stim_sent));
dur_sent   = nan(1, length(stim_sent));
fs         = nan(1, length(stim_sent));
info_sent(length(stim_sent)) = audioinfo(stim_sent(end).name); % Preallocate structure size

for ii = 1:length(stim_sent)
    thisfile = fullfile(stim_sent(ii).folder, stim_sent(ii).name);
    [thisdata, fs(ii)] = audioread(thisfile);
    audio_sent{ii}     = [thisdata, thisdata]';
    info_sent(ii)      = audioinfo(thisfile); 
    dur_sent(ii)       = info_sent(ii).Duration;
end

% TEST -- are the sampling rates of sentence stimuli the same? Code will not
% run correctly if not true
if length(unique(fs)) ~= 1
    error('Check sampling rate of sentences, not equal')
else
    fs = fs(1);
end

% PRIMES
cd(dir_stim_primes)
stim_primes  = dir('*.wav');
audio_primes = cell(1, length(stim_primes));
dur_primes   = repmat([33 65], [1, length(stim_primes)/2]);
% The final onset of drums in the regular/irregular primes happens at 32 or
% 64 seconds, depending on the length of the stimuli. There are a few
% seconds of decay following the last beat. Setting the duration to 33 and
% 65 seconds allows for the pause before sentences to be the same length. 
fs           = horzcat(nan(1, length(stim_primes)), fs);
info_primes(length(stim_primes)) = audioinfo(stim_primes(end).name); % Preallocate structure size

for ii = 1:length(stim_primes)
    thisfile = fullfile(stim_primes(ii).folder, stim_primes(ii).name);
    [thisdata, fs(ii)] = audioread(thisfile);
    audio_primes{ii}   = [thisdata, thisdata]';
    info_primes(ii)    = audioinfo(thisfile); 
%     dur_primes(ii)     = info_primes(ii).Duration;
end

% PRACTICE
cd(dir_stim_pract)
stim_pract  = dir('*.wav');
audio_pract = cell(1, length(stim_pract));
dur_pract   = nan(1, length(stim_pract));
fs          = horzcat(nan(1, length(stim_pract)), fs);
info_pract(length(stim_pract)) = audioinfo(stim_pract(end).name); % Preallocate structure size

for ii = 1:length(stim_pract)
    thisfile = fullfile(stim_pract(ii).folder, stim_pract(ii).name);
    [thisdata, fs(ii)] = audioread(thisfile);
    audio_pract{ii}    = [thisdata, thisdata]';
    info_pract(ii)     = audioinfo(thisfile); 
    dur_pract(ii)      = info_pract(ii).Duration;
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
    inst_file = fullfile(dir_docs, 'instructions_regirreg_16blocks.txt');
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
            PsychPortAudio('FillBuffer', pahandle, audio_pract{16});
            PsychPortAudio('Start', pahandle);
        elseif ii == 7
            PsychPortAudio('FillBuffer', pahandle, audio_pract{15});
            PsychPortAudio('Start', pahandle);
        elseif ii == 9
            PsychPortAudio('FillBuffer', pahandle, audio_pract{16});
            PsychPortAudio('Start', pahandle);
        elseif ii == 11
            PsychPortAudio('FillBuffer', pahandle, audio_pract{13});
            PsychPortAudio('Start', pahandle);
        elseif ii == 14
            PsychPortAudio('FillBuffer', pahandle, audio_pract{26});
            PsychPortAudio('Start', pahandle);
        elseif ii == 16
            PsychPortAudio('FillBuffer', pahandle, audio_pract{27});
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
        pract_text = {'ambiance', 'silence'}; 
        pract_prime = [3 5];
        
        pract_idx = 1;
        
        for blk = 1:2
        
            % Present practice primes (environmental sounds, silence)
            DrawFormattedText(wPtr, ['You will now hear ' pract_text{blk} '.\nPlease stare at the icon\nin the center of the screen.'], 'center', 'center', 255);
            Screen('Flip', wPtr);

            primeStartTarget = GetSecs() + 4; % Start trial 4 seconds from now. 
            % These extra 3 second lets PTB fill the buffer, mark the end of 
            % the stimuli, start the KbQueue
            primeEnd = primeStartTarget + dur_primes(pract_prime(blk));

            PsychPortAudio('FillBuffer', pahandle, audio_primes{pract_prime(blk)});
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

                stimEnd = GetSecs() + dur_pract(key_pract(pract_idx));
                PsychPortAudio('FillBuffer', pahandle, audio_pract{key_pract(pract_idx)});
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
                elseif strcmp(key_pract_direction{pract_idx}, answer{evt}) % If correct
                    correct = correct + 1;
                    DrawFormattedText(wPtr, 'You are correct! Good job!', 'center', 'center', 255);
                else % If wrong
                    DrawFormattedText(wPtr, 'Oops, wrong answer!', 'center', 'center', 255);
                end
                
                pract_idx = pract_idx + 1;

                Screen('Flip', wPtr);
                WaitTill(GetSecs() + 1);
                Screen('Flip', wPtr);
            end
            
            whitenoise = vol_wn*rand(1, t.whitenoise*fs); 
            whitenoise = vertcat(whitenoise, whitenoise);  %#ok<AGROW>
            DrawFormattedText(wPtr, '[white noise]', 'center', 'center', 255);
            Screen('Flip', wPtr);
            PsychPortAudio('FillBuffer', pahandle, whitenoise);
            noisestart = PsychPortAudio('Start', pahandle, [], [], 1);
            WaitTill(noisestart + 5); 
            
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
        
        whitenoise = vol_wn*rand(1, t.whitenoise*fs); 
        whitenoise = vertcat(whitenoise, whitenoise);  %#ok<AGROW>
        PsychPortAudio('FillBuffer', pahandle, whitenoise);
        noisestart = PsychPortAudio('Start', pahandle, [], [], 1);
        WaitTill(noisestart + 5); 

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

rt        = resp - eventEnd;
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
% CLEAR/BABBLE -- 1:Babble sentence (filenames start with a number)
%                 2:Clear sentence
% SUBJ RESP    -- 0:No response/subject timed out
%                 1:Left
%                 2:Right
% CORRECT      -- 0:Wrong answer
%                 1:Right answer
% RT           -- Reaction time (in seconds) relative to end of stimulus.
%                 Inf represents that subject timed out. 

idx = 1;
for ii = 1:4:p.numSent
    data_cell{ii+1, 1} = stim_primes(key_primes(idx)).name;
    data_mat(ii:ii+8, 1) = key_primes(idx);
    idx = idx + 1;
end

for ii = 1:p.numSent
    thissent = stim_sent(key_sent(ii)).name;
    
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
    else % Babble sentences
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
    
    if isinf(rt(ii))
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

function [key_primes, key_sent, key_pract] = generate_keys(subj, p)
% Output 
% key_primes: key containing counterbalanced order of primes. 
% key_sentences: key containing counterbalanced order of sentences. 

% COUNTERBALANCE ORDER OF PRIMES
% Participants can be a member of set A or set B. Set A starts with a
% rhythm block (i.e. regular or irregular prime) and alternates with 
% baseline blocks (i.e. environmental or silent prime). Set B starts with a
% baseline block and alternates with rhythm blocks. Alternating rhythm and
% baseline blocks ensures that there are no contamination effects from
% repeating rhythm blocks. 
key_primes = nan(1, p.blocks);
cb_reg_irr = Shuffle([1 1 2 2 7 7 8 8]);
cb_env_sil = Shuffle([3 3 4 4 5 5 6 6]);
% 1 - Complex/Irregular prime (short)
% 2 - Complex/Irregular prime (long)
% 3 - Environmental/Ambience sound prime (short)
% 4 - Environmental/Ambience sound prime (long)
% 5 - Silent prime (short)
% 6 - Silent prime (long)
% 7 - Simple/Regular prime (short)
% 8 - Simple/Regular prime (long)

% Set the first block as rhythm or baseline depending on whether subject is
% in set A or set B
if strcmp(subj.set, 'A')
    for ii = 1:p.blocks/2
        key_primes(2*ii-1) = cb_reg_irr(ii);
        key_primes(2*ii)   = cb_env_sil(ii);
        % Note that 2*ii-1 indicates the odd-numbered blocks (1, 3, 5, 7), 
        % whereas 2*ii indicates the even-numbered blocks (2, 4, 6, 8). I
        % use this trick because there is a dimension mismatch between
        % cb_reg_irr (4-element vector), cb_env_sil (4-element vector, and 
        % cb_all (8-element vector). 
    end
    
elseif strcmp(subj.set, 'B')
    for ii = 1:p.blocks/2
        key_primes(2*ii-1) = cb_env_sil(ii);
        key_primes(2*ii)   = cb_reg_irr(ii);
    end
    
end

% SHUFFLE ORDER OF SENTENCE STRUCTURES
% Each sentence structure (e.g. ___ who kiss ___ are happy) has four
% constructions (Object-relative Male (OM), Object-relative Female (OF),
% Subject-relative Male (SM), Subject-relative Female (SF)) under two
% auditory conditions (clear and babble). Therefore, there are 4x2 = 8
% different sentences for each structure. These can be indexed by the 
% following vector, which is shuffled across all trials:
key_structures = Shuffle(1:8:p.numStim);

% COUNTERBALANCE NOISE CONDITIONS
% This ensures an equal number of babble OR/SR conditions across all of the
% blocks, and also guarantees a counterbalance of babble/clear across each
% prime across the entire experiment. Note that there are six combinations 
% of noise/clear sentences, but only 16 blocks. I chose to not use the 
% condition where all O-sentences are noise and a block or all S-sentneces 
% are noise. The reason I use 5, 6, 9, and 10 is because I later convert 
% these into binary vectors!

% The following FOR loop counterbalances babble across the "superordinate"
% categories of primes (i.e. reg/irreg/ambiance/silence). This strange 
% Shuffle syntax ensures that the counterbalance matrices are shuffled 
% across column and across row independently, thus preserving
% counterbalance. 
cb_noise = cell(1, 4); 
for ii = 1:4 
    cb_noise{ii} = Shuffle(Shuffle([5, 6; 10, 9], 1), 2);
    % 5  -- OM and SM babble [0 1 0 1]
    % 6  -- OM and SF babble [0 1 1 0]
    % 9  -- OF and SM babble [1 0 0 1]
    % 10 -- OF and SF babble [1 0 1 0]
end

% The following FOR loop counterbalances the order of OR/SR sentences
% across each block and each superordinate category. 

idx_vec = [1 3 1 3 1 3 1 3];
% The first two items in each cb_noise matrix are used to determine the
% "short" prime's noise conditions, and the third and fourth are used in
% the "long" prime's noise conditions. The bizzare Shuffle syntax earlier
% ensures that the short and long primes are counterbalanced, and this
% helps select items 1 and 2, or 3 and 4 from each matrix. 

idx = 1;
key_babble_full = nan(1, p.blocks);

for ii = key_primes % for each prime...
    this_prime = ceil(ii/2); 
    % Above: is the prime complex (1), ambiance (2), silent (3) , or 
    % regular (4)? If so, pull from that cell. 

    key_babble_full(idx) = cb_noise{this_prime}(idx_vec(ii)); 
    % Element idx in the key_noise is thus equal to the correct element
    % from the corresponding cb_noise matrix!
    
    % Don't forget to increase your index!
    idx_vec(ii) = idx_vec(ii) + 1;
    idx = idx + 1;
end


% COUNTERBALANCE SENTENCES WITHIN BLOCKS
% This code ensures that each block of 8 sentences features the same types
% of sentences: 1 clear OM, 1 clear OF, 1 clear SM, 1 clear SF, 1 babble OM,
% 1 babble OF, 1 babble SM, and 1 babble SF. 
key_events = nan(1, p.numSent);
idx = 1;
for ii = 1:4:p.numSent
    con = 0:2:6; % represents OF/OM/SF/SM
    bab = de2bi(key_babble_full(idx), 4, 'left-msb'); % represents which sentences will be babble
    con_bab = Shuffle(con + bab);  % randomizes order of sentences
    key_events(ii:ii+p.stimPerBlock-1) = con_bab; % values 0-7 because key_sent starts at 1
    % 0 -- OF babble
    % 1 -- OF clear
    % 2 -- OM babble
    % 3 -- OM clear
    % 4 -- SF babble
    % 5 -- SF clear
    % 6 -- SM babble 
    % 7 -- SM clear
    idx = idx + 1;
end

% SENTENCES KEY
% Combining key_structures and key_events gives key_sentences, which is the
% sequence of sentences presentation for the experiment. 
key_sent = key_structures + key_events;

% PRACTICE KEY
% Creates one block for practice. Only uses four sentence structures over 8
% different trials, so generating key is a little different. 
key_pract = Shuffle(horzcat((1:p.stimPerBlock:16) + Shuffle(0:3), (17:p.stimPerBlock:32) + Shuffle(0:3)));
    
end

function sentencecheck(key_sent, key_primes, p)
% This function throws an error if there is a problem with the sentences 
% key. It counts the number of object- and subject-relative, male and 
% female, clear and babble sentences and makes sure they are all equal. 
% Then, it makes sure that each block of sentences have one of each 
% category. 
obje = []; 
subj = []; 
male = [];
fema = [];
babb = [];
clea = [];
    
key_obje = sort(horzcat(1:8:p.numStim, 2:8:p.numStim, 3:8:p.numStim, 4:8:p.numStim)); 
key_subj = sort(horzcat(5:8:p.numStim, 6:8:p.numStim, 7:8:p.numStim, 8:8:p.numStim)); 
key_fema = sort(horzcat(1:8:p.numStim, 2:8:p.numStim, 5:8:p.numStim, 6:8:p.numStim));
key_male = sort(horzcat(3:8:p.numStim, 4:8:p.numStim, 7:8:p.numStim, 8:8:p.numStim));
key_babb = (1:2:p.numStim);
key_clea = (2:2:p.numStim);

% Pull out which sentences are male/fem, obj/subj, babble/clear
for ii = 1:length(key_sent)
    if find(key_sent(ii) == key_obje)
        obje = horzcat(obje, key_sent(ii));  %#ok<AGROW>
    elseif find(key_sent(ii) == key_subj) 
        subj = horzcat(subj, key_sent(ii));  %#ok<AGROW>
    end
    
    if find(key_sent(ii) == key_fema)
        fema = horzcat(fema, key_sent(ii));  %#ok<AGROW>
    elseif find(key_sent(ii) == key_male)
        male = horzcat(male, key_sent(ii));  %#ok<AGROW>
    end
    
    if find(key_sent(ii) == key_babb)
        babb = horzcat(babb, key_sent(ii));  %#ok<AGROW>
    elseif find(key_sent(ii) == key_clea)
        clea = horzcat(clea, key_sent(ii));  %#ok<AGROW>
    end
end

% Sort sentences by prime
idx = 1;
each_prime = cell(1, 8);
for ii = key_primes
    each_prime{ii} = horzcat(each_prime{ii}, key_sent(idx:idx+3)); 
    idx = idx + 4;
end

% TEST - does each category have the same number of sentences?
if (length(obje) ~= length(subj))
    error('sentencecheck: Number of object and subject-relative stim not equal')    
elseif (length(fema) ~= length(male))
	error('sentencecheck: Number of female and male stim not equal')
elseif (length(babb) ~= length(clea))
    error('sentencecheck: Number of babble and clear stim not equal')
end

% Check each block of sentences for balance
block = 1;
master_blocks = repmat(0:2:6, [4, 1]) + de2bi([5, 6, 9, 10], 'left-msb');
for ii = 1:p.stimPerBlock:length(key_sent)
    temp1 = key_sent(ii:ii+p.stimPerBlock-1) - 1;
    temp1 = repmat(sort(mod(temp1, 8)), [4, 1]);
    
    if ~any(all(temp1 == master_blocks, 2))
        error(['sentencecheck: block ' num2str(block) ' does not have a legal arrangement of sentences'])
    end
    
    block = block + 1;
end

% Check each prime for counterbalance
for ii = 1:length(each_prime)
    thisblock = sort(mod(each_prime{ii}, 8)); 
    if any(thisblock ~= 0:7)
        error(['sentencecheck: prime category ' num2str(ii) ' does not have equal number of each sentence'])
    end
    
end

end
