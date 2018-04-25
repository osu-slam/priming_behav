%% priming_behav_v1
% Code used to run the priming behavioral experiment. Consists of 8 blocks
% where a prime (regular/irregular rhythm, or environmental/silent
% baseline) is followed by fuzzy speech task using vocoded speech. To 
% administer, press Run, fill out subject information, and guide the 
% participant through the instructions. 
% Author -- Matthew Heard, The Ohio State University:
% heardmatthew49@gmail.com
% 
% CHANGELOG (MM/DD/YY)
% 04/25/18 -- Began coding experiment. -- MH

clear all; clc

%% Collect subject information
prompt = { ...
    'Subject Initials:', ...
    'Subject Number:', ...
    'Subject Set (A or B):', ...
    };
dlg_in = inputdlg(prompt);

subj.init = dlg_in{1};
subj.num  = str2double(dlg_in{2});
subj.set  = upper(dlg_in{3});

%% Set parameters
p.blocks = 8; % number of blocks. 
% NOTE: If p.blocks changes from an even number, double-check generate_keys
% as it will break. I added a test to ensure that p.blocks is an even 
% number before executing the function. 

p.primesPerBlock = 2; % primes per block
% NOTE: IF p.primesPerBlock changes from 2, double-check generate_keys
% as I hard-coded the number of comparisons per block. I added a test to 
% ensure that p.primesPerBlock is 2.

p.numSent = 64; % number of sentence structures
p.numStim = 512; % number of sentence stimuli

%% Pathing and output file names
dir_scripts = pwd;
cd ..
dir_exp = pwd;
dir_results = fullfile(pwd, 'results');
dir_stim    = fullfile(pwd, 'stim');

% A quick bit of sanitation to make it easier to find subject data based on
% subject number... 
if subj.num < 10
    results_tag = ['00' num2str(subj.num) '_' subj.init '_priming_behav_' date];
elseif subj.num < 100
    results_tag = ['0' num2str(subj.num) '_' subj.init '_priming_behav_' date];
elseif subj.num < 1000
    results_tag = [num2str(subj.num) '_' subj.init '_priming_behav_' date];
else
    err('Files will not save with correct name. Check subj.num')
end

results_xls = fullfile(dir_stim, [results_tag, '.xlsx']);
results_mat = fullfile(dir_stim, [results_tag, '.mat']);

% Prevent overwrite of previous data by checking existing results files
cd(dir_results) 
files = dir(results_mat); % Checks if any files share a name
if ~isempty(files)
    results_tag = [results_tag '_run' num2str(length(files)+1)];
    results_xls = fullfile(dir_stim, [results_tag, '.xlsx']);
    results_mat = fullfile(dir_stim, [results_tag, '.mat']);
end
cd(dir_exp)

%% Generate keys
% TESTS -- double checks parameters which, if changed from default, causes
% errors in the code. 
if p.primesPerBlock ~= 2
    error('p.primesPerBlock is no longer 2, check counterbalancing!')
elseif mod(p.blocks, 2) ~= 0
    error('p.blocks is not an even number, check counterbalancing!')
end
[key_primes, key_stimuli] = generate_keys(subj, p);
% For the sake of readability I moved all of this code into a function
% which is specified at the end of this document. 

%% Preallocate required variables
% Preallocating variables before they are called helps keep the timing
% measured by Matlab during the experiment accurate. 




%% Load stimuli into Matlab
% Same as preallocating variables, loading stimuli into Matlab before
% running the code helps keep Matlab's timing accurate. 



%% Open PsychToolbox (PTB) and RTBox
% PTB is used to generate the screen which the participant will see, and to
% present the auditory stimuli. If anyone is interested in learning to use 
% this incredibly powerful toolbox, I highly recommend checking out these 
% tutorials: http://peterscarfe.com/ptbtutorials.html
% RTBox is used to collect subject response and maintain timing of the
% experiment. It was originally designed for use in MRI, but I prefer to
% use it in behavioral experiments as well. There are very few tutorials
% online, so I recommend reading RTBox.m and RTBoxdemo.m 

%% Finish preparing for experiment, run instructions
% To make sure Matlab is keeping accurate timing, it helps to run as little
% code during prime/stimuli presentation and collecting subject response


%% ACTUAL EXPERIMENT %% 
%% Present prime




%% Present stimuli




%% Collect response




%% Catch
% Note that the entire experiment is written between a try/catch loop. This
% prevents the experiment from not saving data when it encounters an error.
% Note that pressing escape during the experiment to quit causes RTBox to 
% throw an error. 





%% Close the experiment and save data
% If the experiment does not encounter any errors, then this section is
% responsible for saving the output. 



%% Supporting functions
% Here are all of the functions I wrote for this experiment. Keeping them
% down here makes the code more readable and cuts down on the number of
% variables produced by the script. 

function [key_primes, key_stimuli] = generate_keys(subj, p)
% Output 
% key_primes: key containing counterbalanced order of primes. 
% key_stimuli: key containing counterbalanced order of stimuli. 

% COUNTERBALANCE ORDER OF PRIMES
% Participants can be a member of set A or set B. Set A starts with a
% rhythm block (i.e. regular or irregular prime) and alternates with 
% baseline blocks (i.e. environmental or silent prime). Set B starts with a
% baseline block and alternates with rhythm blocks. Alternating rhythm and
% baseline blocks ensures that there are no contamination effects from
% repeating rhythm blocks. 
key_primes = cell(1, p.blocks);
cb_reg_irr = Shuffle({'reg' 'reg' 'irr' 'irr'});
cb_env_sil = Shuffle({'env' 'env' 'sil' 'sil'});
% 'reg' - Regular prime
% 'irr' - Irregular prime
% 'env' - Environmental sound prime
% 'sil' - Silent prime

% Set the first block as rhythm or baseline depending on whether subject is
% in set A or set B
if strcmp(subj.set, 'A')
    for ii = 1:p.blocks/2
        key_primes{2*ii-1} = cb_reg_irr{ii};
        key_primes{2*ii}   = cb_env_sil{ii};
        % Note that 2*ii-1 indicates the odd-numbered blocks (1, 3, 5, 7), 
        % whereas 2*ii indicates the even-numbered blocks (2, 4, 6, 8). I
        % use this trick because there is a dimension mismatch between
        % cb_reg_irr (4-element vector), cb_env_sil (4-element vector, and 
        % cb_all (8-element vector). 
    end
    
elseif strcmp(subj.set, 'B')
    for ii = 1:p.blocks/2
        key_primes{2*ii-1} = cb_env_sil{ii};
        key_primes{2*ii}   = cb_reg_irr{ii};
    end
    
end

% SHUFFLE ORDER OF SENTENCE STRUCTURES
% Each sentence structure (e.g. ___ who kiss ___ are happy) has four
% constructions (Object-relative Male (OM), Object-relative Female (OF),
% Subject-relative Male (SM), Subject-relative Female (SF)) under two
% auditory conditions (clear and vocoded). Therefore, there are 4x2 = 8
% different stimuli for each sentence structure. These can be indexed by
% the following vector, which is shuffled across all trials:
key_sent = Shuffle(1:8:p.numStim);

% COUNTERBALANCE STIMULI WITHIN BLOCKS
% This code ensures that each block of 8 sentences features the same types
% of stimuli: 1 clear OM, 1 clear OF, 1 clear SM, 1 clear SF, 1 vocoded OM,
% 1 vocoded OF, 1 vocoded SM, and 1 vocoded SF. 
key_events = nan(1, p.numSent);
for ii = 1:8:p.numSent
    temp = Shuffle(0:7); 
    key_events(ii:ii+7) = temp; % has 1-7 because key_sent starts at 1
end

% STIMULI KEY
% Combining key_sent and key_events gives key_master, which is the
% sequence of language stimuli presentation for the experiment. 
key_stimuli = key_sent + key_events;

end

