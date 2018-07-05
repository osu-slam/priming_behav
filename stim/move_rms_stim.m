cd('C:\Users\heard.49\Documents\GitHub\priming_behav\stim\sentences')

files = dir('*.wav');

dir_rmse = pwd;
% dir_prac = 'C:\Users\heard.49\Documents\GitHub\priming_behav\stim\practice';
% dir_acde = 'C:\Users\heard.49\Documents\GitHub\priming_behav\stim\primes_accel_decel';
% dir_reir = 'C:\Users\heard.49\Documents\GitHub\priming_behav\stim\primes_reg_irreg';
dir_sent = 'C:\Users\heard.49\Documents\GitHub\priming_behav\stim\sentences';
dir_snr2 = 'C:\Users\heard.49\Documents\GitHub\priming_behav\stim\sentences_snr-2';

for ii = 1:length(files)
    thisfile = files(ii).name;
    
    if strcmp(thisfile(end-5:end-4), '-2') % snr-2
        movefile(thisfile, dir_snr2)
%     elseif any(strcmp(thisfile(7:10), {'clea', 'SNR0'}))
%         if str2double(thisfile(2:3)) >= 67
%             movefile(thisfile, dir_prac)
%         else
%             movefile(thisfile, dir_sent)
%         end
        
    end
    
end