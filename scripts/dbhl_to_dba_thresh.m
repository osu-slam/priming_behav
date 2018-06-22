%% dbhl_to_dba_thresh
% converts db hl to dba. 
% Input: dbhl_vec, a matrix of measurements from pure tone audiometry test.
%   The first row is from the left ear, and the second row is from the
%   right ear. From left to right, the columns are frequencies (0.25, 0.5,
%   1, 2, 4, 8 kHz standard, but can fit any number of values.)
% Output: dba_match, a value which is 35 db above the pure tone audiometry
%   average, the threshold which sound should be set at within the 
%   soundbooth.
% Example: dhbl_to_dba_thresh([25 20 0 5 -5 -10; 25 25 5 -5 -5 -5])

% MM/DD/YY -- Changelog
% 06/19/18 -- Made version 1, 95% certain this doesn't work and I'm gonna
%   talk to Dr. Feth to find a better way to do it. Shame to delete code 
%   that may come in handy though! -- MH

function dba_match = dbhl_to_dba_thresh(dbhl_vec)

%% Test input
if ~ismatrix(dbhl_vec) || any(size(dbhl_vec) ~= [2, 6])
    error('Input should be a vector of size [2, 6]: one row for each ear, and one column for each frequency')
end

%% Convert from dbhl to dbspl
dbspl_vec = dbhl_vec + repmat([27, 13.5, 7.5, 9, 12, 15.5], 2, 1);

%% Calculate PTA in units of dbspl
dbspl_pta = mean(dbspl_vec, 2); 
dbspl_pta_max = max(dbspl_pta); 

%% Convert from dbspl to dba
Ra = @(f) (12194^2 * f^4)/((f^2 + 20.6^2) * sqrt((f^2 + 107.7^2)*(f^2 + 737.9^2)) * (f^2 + 12194^2)); 
dba_thresh = 20*log10(Ra(dbspl_pta_max)) + 2; 

%% Calculate 35 db above threshold
dba_match = dba_thresh + 35;

end