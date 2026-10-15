%% DSP Mini-Project 26: Audio Sample-Rate Conversion for Voice Communication
% Study of quality loss and computational cost in interpolation/decimation.
% Requires: Signal Processing Toolbox (upfirdn, firpm, resample, spectrogram)
% Run from a folder that contains dataset/speech.flac (a LibriSpeech file).
% If the file is missing, MATLAB's built-in speech sample (mtlb) is used.

clear; clc; close all;
outDir = 'results'; if ~exist(outDir,'dir'), mkdir(outDir); end

%% 1. LOAD INPUT SIGNAL (reference rate = 16 kHz, LibriSpeech native rate)
fsRef = 16000;
inputFile = fullfile('dataset','speech.flac');
if isfile(inputFile)
    [x,fs] = audioread(inputFile);
else
    warning('LibriSpeech file not found - using built-in speech (mtlb).');
    S = load('mtlb'); x = S.mtlb; fs = S.Fs;
end
x = x(:,1);
if fs ~= fsRef, x = resample(x,fsRef,fs); end
x = x(1:min(end,10*fsRef));          % first 10 s
x = x/max(abs(x));                   % normalise
N = numel(x);

%% 2. EXPERIMENT SETUP
% Each row [L M]: output rate = fsRef*L/M
ratios = [1 2;    % 16 -> 8 kHz   (telephony narrowband)
          3 4;    % 16 -> 12 kHz
          3 2;    % 16 -> 24 kHz
          2 1;    % 16 -> 32 kHz
          3 1];   % 16 -> 48 kHz

% Methods: each has a filter-design step (not timed) and a conversion step (timed)
m = {};
m{end+1} = struct('name','Linear interp (no AA)', ...
    'design',@(L,M) [], 'conv',@(x,L,M,h) src_linear(x,L,M));
for K = [4 10 30]
    m{end+1} = struct('name',sprintf('Kaiser K=%d',K), ...
        'design',@(L,M) design_kaiser(L,M,K), 'conv',@(x,L,M,h) src_fir(x,L,M,h));
end
m{end+1} = struct('name','Equiripple K=10', ...
    'design',@(L,M) design_equiripple(L,M,10), 'conv',@(x,L,M,h) src_fir(x,L,M,h));
m{end+1} = struct('name','IIR Butterworth-8', ...
    'design',@(L,M) [], 'conv',@(x,L,M,h) src_iir(x,L,M,8));
m{end+1} = struct('name','MATLAB resample (baseline)', ...
    'design',@(L,M) [], 'conv',@(x,L,M,h) resample(x,L,M));
nM = numel(m); nR = size(ratios,1);

%% 3. RUN ALL EXPERIMENTS (round trip: 16k -> target -> 16k)
SNRfull = zeros(nR,nM); SNRband = SNRfull; LSD = SNRfull; tRun = SNRfull;
trim = 1600+1 : N-1600;                       % ignore 0.1 s edge transients
snr = @(ref,est) 10*log10(sum(ref.^2)/sum((ref-est).^2));

for r = 1:nR
    L = ratios(r,1); M = ratios(r,2); fsT = fsRef*L/M;
    fc = min(fsRef,fsT)/2;                    % common bandwidth
    xb = brickwall(x,fsRef,fc);               % ideal band-limited reference
    for k = 1:nM
        h  = m{k}.design(L,M);
        y  = m{k}.conv(x,L,M,h);              % forward conversion
        xr = m{k}.conv(y,M,L,h);              % back to 16 kHz
        xr = fixlen(xr,N);
        SNRfull(r,k) = snr(x(trim),xr(trim));     % vs original
        SNRband(r,k) = snr(xb(trim),xr(trim));    % vs ideal band-limited
        LSD(r,k)     = lsd(x,xr,fsRef,0.95*fc);
        tRun(r,k)    = timeit(@() m{k}.conv(x,L,M,h));
        fprintf('%2d/%-2d  %-28s SNR=%6.2f dB  inband=%6.2f dB  LSD=%5.2f dB  t=%7.2f ms\n', ...
            L,M,m{k}.name,SNRfull(r,k),SNRband(r,k),LSD(r,k),1e3*tRun(r,k));
    end
end
SNRfull(isinf(SNRfull)) = NaN;  SNRband(SNRband > 200) = NaN;
%% 4. SAVE RESULTS TABLE
names = cellfun(@(s) s.name,m,'UniformOutput',false);
rows = {}; 
for r = 1:nR
    for k = 1:nM
        rows(end+1,:) = {sprintf('%d/%d',ratios(r,1),ratios(r,2)), fsRef*ratios(r,1)/ratios(r,2), ...
            names{k}, SNRfull(r,k), SNRband(r,k), LSD(r,k), 1e3*tRun(r,k)}; %#ok<SAGROW>
end, end
T = cell2table(rows,'VariableNames',{'Ratio','FsOut_Hz','Method','SNR_dB','InBandSNR_dB','LSD_dB','Runtime_ms'});
writetable(T,fullfile(outDir,'results_table.csv')); disp(T);

%% 5. PLOTS
lbl = arrayfun(@(r) sprintf('%d/%d',ratios(r,1),ratios(r,2)),1:nR,'UniformOutput',false);

% (a) in-band SNR
figure; bar(SNRband); set(gca,'XTickLabel',lbl); legend(names,'Location','bestoutside');
xlabel('Conversion ratio L/M'); ylabel('In-band SNR (dB)'); title('Round-trip in-band SNR'); grid on;
saveas(gcf,fullfile(outDir,'fig_snr.png'));

% (b) LSD
figure; bar(LSD); set(gca,'XTickLabel',lbl); legend(names,'Location','bestoutside');
xlabel('Conversion ratio L/M'); ylabel('Log-spectral distance (dB)'); title('Spectral distortion'); grid on;
saveas(gcf,fullfile(outDir,'fig_lsd.png'));

% (c) runtime
figure; bar(1e3*tRun); set(gca,'XTickLabel',lbl,'YScale','log'); legend(names,'Location','bestoutside');
xlabel('Conversion ratio L/M'); ylabel('Runtime (ms, log)'); title('Computational cost (10 s of audio)'); grid on;
saveas(gcf,fullfile(outDir,'fig_runtime.png'));

% (d) filter frequency responses for 16 -> 8 kHz (L=1, M=2)
figure; hold on;
for K = [4 10 30]
    [H,f] = freqz(design_kaiser(1,2,K),1,4096,fsRef); plot(f,20*log10(abs(H)+eps));
end
[H,f] = freqz(design_equiripple(1,2,10),1,4096,fsRef); plot(f,20*log10(abs(H)+eps));
xline(4000,'k--','Target Nyquist (4 kHz)'); ylim([-120 5]); grid on;
legend('Kaiser K=4','Kaiser K=10','Kaiser K=30','Equiripple K=10');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)'); title('Anti-alias filter responses (16 -> 8 kHz)');
saveas(gcf,fullfile(outDir,'fig_filters.png'));

% (e) aliasing demo: spectrograms after 16 -> 8 -> 16 kHz round trip
iNo = 1; iKa = 3;  % linear (no AA) vs Kaiser K=10
L=1; M=2;
xr_no = fixlen(m{iNo}.conv(m{iNo}.conv(x,L,M,[]),M,L,[]),N);
h = m{iKa}.design(L,M);
xr_ka = fixlen(m{iKa}.conv(m{iKa}.conv(x,L,M,h),M,L,h),N);
figure;
subplot(3,1,1); spectrogram(x,hamming(512),256,512,fsRef,'yaxis'); title('Original 16 kHz');
subplot(3,1,2); spectrogram(xr_no,hamming(512),256,512,fsRef,'yaxis'); title('Round trip via 8 kHz - no anti-alias filter');
subplot(3,1,3); spectrogram(xr_ka,hamming(512),256,512,fsRef,'yaxis'); title('Round trip via 8 kHz - Kaiser K=10');
saveas(gcf,fullfile(outDir,'fig_spectrograms.png'));

% (f) average spectra
figure;
[P0,f] = pwelch(x,hamming(1024),512,1024,fsRef);
P1 = pwelch(xr_no,hamming(1024),512,1024,fsRef);
P2 = pwelch(xr_ka,hamming(1024),512,1024,fsRef);
plot(f,10*log10(P0),f,10*log10(P1),f,10*log10(P2)); grid on;
legend('Original','No AA filter','Kaiser K=10'); xlabel('Frequency (Hz)'); ylabel('PSD (dB/Hz)');
title('Spectrum after 16 -> 8 -> 16 kHz'); saveas(gcf,fullfile(outDir,'fig_psd.png'));

%% 6. SAVE AUDIO FOR LISTENING TESTS
audiowrite(fullfile(outDir,'original_16k.wav'),x,fsRef);
y8 = fixlen(m{iKa}.conv(x,1,2,h), N/2);
audiowrite(fullfile(outDir,'8k_kaiser10.wav'), 0.99*y8/max(abs(y8)), 8000);
audiowrite(fullfile(outDir,'roundtrip_noAA.wav'),xr_no/max(abs(xr_no)),fsRef);
audiowrite(fullfile(outDir,'roundtrip_kaiser10.wav'),xr_ka/max(abs(xr_ka)),fsRef);

%% ===================== LOCAL FUNCTIONS =====================
function h = design_kaiser(L,M,K)
% Windowed-sinc low-pass. Cutoff = pi/max(L,M). Length = 2*K*max(L,M)+1
    Q = max(L,M); n = 2*K*Q;
    h = fir1(n,1/Q,kaiser(n+1,8))';
end

function h = design_equiripple(L,M,K)
% Parks-McClellan low-pass with same length as Kaiser design
    Q = max(L,M); n = 2*K*Q;
    h = firpm(n,[0 0.85/Q 1.05/Q 1],[1 1 0 0])';
end

function y = src_fir(x,L,M,h)
% Rational conversion by L/M: upsample by L -> FIR low-pass -> downsample by M
% (upfirdn implements this efficiently as a polyphase filter bank)
    h = L*h(:);                                  % gain L compensates zero insertion
    D = (numel(h)-1)/2;  Dm = M*ceil(D/M);       % make delay a multiple of M
    pad = Dm-D;  h = [zeros(pad,1); h; zeros(pad,1)];
    nOut = ceil(numel(x)*L/M);
    xp = [x(:); zeros(ceil(Dm/L)+M,1)];
    yy = upfirdn(xp,h,L,M);
    y  = yy(Dm/M+1 : Dm/M+nOut);                 % remove filter delay
end

function y = src_iir(x,L,M,order)
% Same structure but with zero-phase Butterworth IIR (filtfilt)
    Q = max(L,M);
    [z,p,k] = butter(order,1/Q); [sos,g] = zp2sos(z,p,k);
    xu = zeros(numel(x)*L,1); xu(1:L:end) = L*x(:);
    xf = filtfilt(sos,g,xu);
    y = xf(1:M:end); y = y(1:ceil(numel(x)*L/M));
end

function y = src_linear(x,L,M)
% Naive method: linear interpolation at new time grid, NO anti-alias filter
    n = numel(x); nOut = ceil(n*L/M);
    t = (0:nOut-1)' * M/L;
    y = interp1((0:n-1)',x(:),t,'linear',0);
end

function xb = brickwall(x,fs,fc)
% Ideal band-limiting in the FFT domain (used only as a reference signal)
    n = numel(x); X = fft(x); f = (0:n-1)'*fs/n; f = min(f,fs-f);
    X(f>fc) = 0; xb = real(ifft(X));
end

function y = fixlen(y,n)
    y = y(:); if numel(y)<n, y(end+1:n) = 0; else, y = y(1:n); end
end

function d = lsd(x,xr,fs,fcut)
% Log-spectral distance (dB) averaged over frames, below fcut
    [S1,f] = spectrogram(x ,hamming(512),256,512,fs);
    S2     = spectrogram(xr,hamming(512),256,512,fs);
    b = f<=fcut;
    P1 = abs(S1(b,:)).^2+1e-10; P2 = abs(S2(b,:)).^2+1e-10;
    d = mean(sqrt(mean((10*log10(P1./P2)).^2,1)));
end