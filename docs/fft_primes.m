close all
clearvars
cd ..
cd stim
cd primes_reg_irreg_16blocks

files = dir('*.wav');

for ii = 1:length(files)
    [X, Fs] = audioread(files(ii).name); % Signal, Sampling frequency 
    if contains(files(ii).name, '_')
        name = insertBefore(files(ii).name, '_', '\');
    else
        name = files(ii).name;
    end
    
    if size(X, 2) == 2
        X = (X(:, 1) + X(:, 2))/2;
    end
    
    L = length(X); % Length of signal

    Y = fft(X);

    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);

    f = Fs*(0:(L/2))/L;
    figure
    plot(f,P1) 
    title(['Single-Sided Amplitude Spectrum of ' name])
    xlabel('f (Hz)')
    ylabel('|P1(f)|')
    axis([0 20 0 1*10^-4])
end