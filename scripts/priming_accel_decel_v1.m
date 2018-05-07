%% priming_behav_v1
% Code used to run the priming behavioral experiment. Consists of 8 blocks
% where a prime (accelerating/decelerating pulse, or constant/silent
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
% 05/03/18 -- Finished stimuli, code is complete! -- MH
% 05/04/18 -- Cloned accelerating/decelerating version. -- MH

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

p.blocks = 8; % number of blocks. 
% NOTE: If p.blocks changes from an even number, double-check generate_keys
% as it will break. I added a test to ensure that p.blocks is an even 
% number before executing the function. 

p.repPrimesPerExp = 2; % primes per block
% NOTE: IF p.repPrimesPerExp changes from 2, double-check 
% generate_keys as I hard-coded the number of comparisons per block. I 
% added a test to ensure that p.repPrimesPerExp is 2.

p.stimPerBlock = 8; % number of sentences in each block
p.numSent = 64; % number of sentence structures
p.numStim = 512; % number of sentence .wav files

t.rxnWindow = 5; % Length of reaction time window after stimuli
% NOTE: If this changes from 5 seconds, change the instructions accordingly

%% Pathing and output file names
dir_scripts = pwd;
cd ..
dir_exp  = pwd;
dir_docs = fullfile(pwd, 'docs');
dir_results = fullfile(pwd, 'results');
dir_stim_primes = fullfile(pwd, 'stim', 'primes_accel_decel');
dir_stim_sent   = fullfile(pwd, 'stim', 'sentences');
dir_stim_pract  = fullfile(pwd, 'stim', 'practice');

% A quick bit of sanitation to make it easier to find subject data based on
% subject number... 
if subj.num < 10
    results_tag = ['00' num2str(subj.num) '_' subj.init '_priming_accel_decel_' date];
elseif subj.num < 100
    results_tag = ['0' num2str(subj.num) '_' subj.init '_priming_accel_decel_' date];
elseif subj.num < 1000
    results_tag = [num2str(subj.num) '_' subj.init '_priming_accel_decel_' date];
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
sentencecheck(key_sent, p)
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
DrawFormattedText(wPtr, 'Please wait, preparing experiment...', [], [], 255);
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
RTBox('ButtonNames', {'left', 'right', '3', '4'});

% I convert the speaker image matrix into a texture at this point so the
% experiment runs faster. 
speaker_tex = Screen('MakeTexture', wPtr, speaker_mat);

%% Finish preparing for experiment, run instructions
if ~NoTutorial
% Read in each line of instructions
    inst_file = fullfile(dir_docs, 'instructions_acceldecel_v1.txt');
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
    noClear = [0 0 0 0 0 0 0 0 1 0 1 0 0 1 0 1 0 0 0 0 0];
    for ii = 1:19
        if any(ii == [10, 12, 15, 17])
            DrawFormattedText(wPtr, inst_lines{ii}, 'center', centerY + 200, 255);
        else
            DrawFormattedText(wPtr, inst_lines{ii}, 'center', 'center', 255);
        end

        Screen('Flip', wPtr, [], noClear(ii));
        WaitSecs(0.5);

        if ii == 5
            PsychPortAudio('FillBuffer', pahandle, audio_pract{8});
            PsychPortAudio('Start', pahandle);
        elseif ii == 7
            PsychPortAudio('FillBuffer', pahandle, audio_pract{7});
            PsychPortAudio('Start', pahandle);
        elseif ii == 9
            PsychPortAudio('FillBuffer', pahandle, audio_pract{8});
            PsychPortAudio('Start', pahandle);
        elseif ii == 11
            PsychPortAudio('FillBuffer', pahandle, audio_pract{5});
            PsychPortAudio('Start', pahandle);
        elseif ii == 14
            PsychPortAudio('FillBuffer', pahandle, audio_pract{10});
            PsychPortAudio('Start', pahandle);
        elseif ii == 16
            PsychPortAudio('FillBuffer', pahandle, audio_pract{19});
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
                DrawFormattedText(wPtr, 'Too Slow! Be sure to respond quicker.', 'center', 'center', 255);
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
        if strcmp(cont, 'right')
            DrawFormattedText(wPtr, inst_lines{21}, 'center', 'center', 255);
            Screen('Flip', wPtr);
            WaitTill(GetSecs + 0.5);
            RTBox('Clear');
            RTBox(inf);
            break
        else
            Screen('Flip', wPtr);
        end

    end
    
else
    DrawFormattedText(wPtr, 'Press right arrow to begin experiment.', 'center', 'center', 255);
    Screen('Flip', wPtr);
    RTBox('Clear');
    RTBox(inf);
end

%% ACTUAL EXPERIMENT %% 
% Preallocating variables
for ii = 1:p.blocks
    thisfield = ['block', num2str(ii)];
    pulse.(thisfield) = []; % Preallocate pulse struct
end
pulse_fields = fields(pulse);

answer = cell(1, p.numSent);
resp = nan(1, p.numSent);
eventEnd = nan(1, p.numSent);

primeStart = nan(1, p.blocks);
evt = 1; % Index will increase after each trial

try
    for blk = 1:p.blocks        
        %% Present prime
        WaitTill(GetSecs() + 1);
        
        Screen('DrawTexture', wPtr, speaker_tex);
        Screen('Flip', wPtr);
        
        pulse_temp = nan(1, 100);
        primeStartTarget = GetSecs() + 1; % Start trial 1 second from now. 
        % This extra 1 second lets PTB fill the buffer, mark the end of the
        % stimuli, and start the KbQueue. 
        primeEnd = primeStartTarget + dur_primes(key_primes(blk));
        PsychPortAudio('FillBuffer', pahandle, audio_primes{key_primes(blk)});
        
        idx = 1;
        KbQueueCreate
        KbQueueStart
        primeStart(blk) = PsychPortAudio('Start', pahandle, [], primeStartTarget, 1);
        while GetSecs() < primeEnd 
            [keyIsDown, timeAndKey] = KbQueueCheck;
            if keyIsDown
                pulse_temp(idx) = timeAndKey(32); 
                % Using a temp variable might save time?
                % Also note that 32 is the keycode for space. Any other key
                % press is effectively ignored. 
                idx = idx + 1;
            end
            
        end
        
        KbQueueRelease % Ends recording of subject response. 
        
        pulse.(pulse_fields{blk}) = pulse_temp;
        
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

rt        = resp - eventEnd;
data_cell = cell(p.numSent + 1, 7);
data_mat  = nan(p.numSent, 7);

% Remove nans from pulse data and convert from absolute to time relative to
% start of pulse
for ii = 1:length(pulse_fields)
    % Screen out zeros, which are incorrect key presses. 
    tempPulse = pulse.(pulse_fields{ii})(pulse.(pulse_fields{ii}) > 0); 
    
    % Screen out NaNs, which are unused preallocated spots in the variable. 
    pulse.(pulse_fields{ii}) = tempPulse(~isnan(tempPulse)); 
    
    tempPulseStart = repmat(primeStart(ii), 1, length(pulse.(pulse_fields{ii})));
    pulse_rel.(pulse_fields{ii}) = pulse.(pulse_fields{ii}) - tempPulseStart;
    for jj = 2:length(pulse_rel.(pulse_fields{ii}))
        pulse_dt.(pulse_fields{ii})(jj-1) = pulse_rel.(pulse_fields{ii})(jj) - pulse_rel.(pulse_fields{ii})(jj-1);
    end
    
end

% This is the format for the columns of the behavioral data within 
% data_cell and data_mat. The pulse data saves within data_mat as a series
% of structures. 
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
for ii = 1:8:p.numSent
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
save(results_mat, 'data_mat', 'pulse_rel', 'pulse_dt');

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
cb_acc_dec = Shuffle([1 1 3 3]);
cb_con_sil = Shuffle([2 2 4 4]);
% 1 - Accelerating pulse prime
% 2 - Constant pulse prime
% 3 - Decelerating pulse prime
% 4 - Silent prime

% Set the first block as rhythm or baseline depending on whether subject is
% in set A or set B
if strcmp(subj.set, 'A')
    for ii = 1:p.blocks/2
        key_primes(2*ii-1) = cb_acc_dec(ii);
        key_primes(2*ii)   = cb_con_sil(ii);
        % Note that 2*ii-1 indicates the odd-numbered blocks (1, 3, 5, 7), 
        % whereas 2*ii indicates the even-numbered blocks (2, 4, 6, 8). I
        % use this trick because there is a dimension mismatch between
        % cb_reg_irr (4-element vector), cb_env_sil (4-element vector, and 
        % cb_all (8-element vector). 
    end
    
elseif strcmp(subj.set, 'B')
    for ii = 1:p.blocks/2
        key_primes(2*ii-1) = cb_con_sil(ii);
        key_primes(2*ii)   = cb_acc_dec(ii);
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

% COUNTERBALANCE SENTENCES WITHIN BLOCKS
% This code ensures that each block of 8 sentences features the same types
% of sentences: 1 clear OM, 1 clear OF, 1 clear SM, 1 clear SF, 1 babble OM,
% 1 babble OF, 1 babble SM, and 1 babble SF. 
key_events = nan(1, p.numSent);
for ii = 1:8:p.numSent
    temp = Shuffle(0:7); 
    key_events(ii:ii+7) = temp; % has 1-7 because key_sent starts at 1
    % 0 -- OF babble
    % 1 -- OF clear
    % 2 -- OM babble
    % 3 -- OM clear
    % 4 -- SF babble
    % 5 -- SF clear
    % 6 -- SM babble 
    % 7 -- SM clear
end

% SENTENCES KEY
% Combining key_structures and key_events gives key_sentences, which is the
% sequence of sentences presentation for the experiment. 
key_sent = key_structures + key_events;

% PRACTICE KEY
% Creates one block for practice. Only uses four sentence structures over 8
% different trials, so generating key is a little different. 
key_pract = Shuffle([1:p.stimPerBlock:32, 1:p.stimPerBlock:32]) + Shuffle(0:7);
    
end

function sentencecheck(key_sentences, p)
% This function throws an error if there is a problem with the sentences 
% key. It counts the number of object- and subject-relative, male and 
% female, clear and babble sentences and makes sure they are all equal. 
% Then, it makes sure that each block of sentences have one of each 
% category. 
obj    = []; 
subj   = []; 
male   = [];
fem    = [];
babble = [];
clear  = [];
    
key_obj    = sort(horzcat(1:8:p.numStim, 2:8:p.numStim, 3:8:p.numStim, 4:8:p.numStim)); 
key_subj   = sort(horzcat(5:8:p.numStim, 6:8:p.numStim, 7:8:p.numStim, 8:8:p.numStim)); 
key_fem    = sort(horzcat(1:8:p.numStim, 2:8:p.numStim, 5:8:p.numStim, 6:8:p.numStim));
key_male   = sort(horzcat(3:8:p.numStim, 4:8:p.numStim, 7:8:p.numStim, 8:8:p.numStim));
key_babble = (1:2:p.numStim);
key_clear  = (2:2:p.numStim);

% Pull out which sentences are male/fem, obj/subj, babble/clear
for ii = 1:length(key_sentences)
    if find(key_sentences(ii) == key_obj)
        obj = horzcat(obj, key_sentences(ii));  %#ok<AGROW>
    elseif find(key_sentences(ii) == key_subj) 
        subj = horzcat(subj, key_sentences(ii));  %#ok<AGROW>
    end
    
    if find(key_sentences(ii) == key_fem)
        fem = horzcat(fem, key_sentences(ii));  %#ok<AGROW>
    elseif find(key_sentences(ii) == key_male)
        male = horzcat(male, key_sentences(ii));  %#ok<AGROW>
    end
    
    if find(key_sentences(ii) == key_babble)
        babble = horzcat(babble, key_sentences(ii));  %#ok<AGROW>
    elseif find(key_sentences(ii) == key_clear)
        clear = horzcat(clear, key_sentences(ii));  %#ok<AGROW>
    end
end

% TEST - does each category have the same number of sentences?
if (length(obj) ~= length (subj))
    error('sentencecheck: Number of object and subject-relative stim not equal')    
elseif (length(fem) ~= length (male))
	error('sentencecheck: Number of female and male stim not equal')
elseif (length(babble) ~= length (clear))
    error('sentencecheck: Number of babble and clear stim not equal')
end

% Check each block of sentences for balance
block = 1;
for ii = 1:p.stimPerBlock:length(key_sentences)
    temp = key_sentences(ii:ii+7);
    temp = sort(mod(temp, 8));
    if ~isequal(temp, 0:7)
        error(['sentencecheck: block ' num2str(block) ' does not have one of each stim type'])
    end
    block = block + 1;
end

end
