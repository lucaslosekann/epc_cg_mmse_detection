% parameters
simulation_name = '128x8_64QAM'; % simulation name 
M = 128; % # of antennas
K = 8; % # of users (K < M)
modulation_type = '64QAM'; % modulation type: 'BPSK','QPSK','16QAM','64QAM'
carriers = 100;
SNRdB_range = 0:2:10; % dB values range
detector = {'CG-MMSE'}; % detector used
    
% symboling (according to IEEE 802.11)
switch (modulation_type)
    case 'BPSK',
        symbols = [ -1 1 ];
    case 'QPSK',
        symbols = [ -1-1i,-1+1i, ...
            +1-1i,+1+1i ];
    case '16QAM',
        symbols = [ -3-3i,-3-1i,-3+3i,-3+1i, ...
            -1-3i,-1-1i,-1+3i,-1+1i, ...
            +3-3i,+3-1i,+3+3i,+3+1i, ...
            +1-3i,+1-1i,+1+3i,+1+1i ];
    case '64QAM',
        symbols = [ -7-7i,-7-5i,-7-1i,-7-3i,-7+7i,-7+5i,-7+1i,-7+3i, ...
            -5-7i,-5-5i,-5-1i,-5-3i,-5+7i,-5+5i,-5+1i,-5+3i, ...
            -1-7i,-1-5i,-1-1i,-1-3i,-1+7i,-1+5i,-1+1i,-1+3i, ...
            -3-7i,-3-5i,-3-1i,-3-3i,-3+7i,-3+5i,-3+1i,-3+3i, ...
            +7-7i,+7-5i,+7-1i,+7-3i,+7+7i,+7+5i,+7+1i,+7+3i, ...
            +5-7i,+5-5i,+5-1i,+5-3i,+5+7i,+5+5i,+5+1i,+5+3i, ...
            +1-7i,+1-5i,+1-1i,+1-3i,+1+7i,+1+5i,+1+1i,+1+3i, ...
            +3-7i,+3-5i,+3-1i,+3-3i,+3+7i,+3+5i,+3+1i,+3+3i ];
end

% extract average symbol energy
symbol_energy = mean(abs(symbols).^2);

% precompute bit labels
Q = log2(length(symbols)); % number of bits per symbol
input_bits = single(de2bi(0:length(symbols)-1,Q,'left-msb')); % input bit stream

% track simulation time
time_elapsed = 0;

% start simulation
% initialize result arrays (detector x SNR)
VER = zeros(length(detector),length(SNRdB_range), 'single'); % vector error rate
SER = zeros(length(detector),length(SNRdB_range), 'single'); % symbol error rate
BER = zeros(length(detector),length(SNRdB_range), 'single'); % bit error rate

% generate random bit stream (antenna x bit x trial)
bits = randi([0 1], K, Q, carriers, 'single');

% sub-carriers loop
tic
for t=1:carriers
    
    % generate transmit symbol
    idx = bi2de(bits(:,:,t),'left-msb')+1;
    s = symbols(idx).'; % indexed symbols
    
    % generate channel matrix & noise vector
    n = sqrt(0.5)*(single(randn(M,1))+1i*single(randn(M,1)));
    H = sqrt(0.5)*(single(randn(M,K))+1i*single(randn(M,K)));

    % transmit over noiseless channel
    x = single(H*s);
    
    % SNR loop
    for k=1:length(SNRdB_range)
        
        % compute noise variance 
        N0 = single(K*symbol_energy*10^(-SNRdB_range(k)/10));
        
        % transmit data over noisy channel
        y = single(x+sqrt(N0)*n);

        % algorithm loop
        for d=1:length(detector)
            
            switch (detector{d}) % select algorithms
                case 'CG-MMSE'
                    [idxhat,bithat] = CG_MMSE_detector(H,y,K,symbols,input_bits,N0);
                otherwise
                    error('type not defined.')
            end
            
            % compute error metrics
            err = (idx~=idxhat);
            VER(d,k) = VER(d,k) + any(err);
            SER(d,k) = SER(d,k) + sum(err)/K;
            BER(d,k) = BER(d,k) + sum(sum(bits(:,:,t)~=bithat))/(K*Q);
            
        end % algorithm loop
        
    end % SNR loop
    
    % keep track of simulation time
    if toc>10
        time=toc;
        time_elapsed = time_elapsed + time;
        fprintf('estimated remaining simulation time: %3.0f min.\n',time_elapsed*(carriers/t-1)/60);
        tic
    end
    
end % sub-carriers loop

% normalize results
VER = VER/carriers;
SER = SER/carriers;
BER = BER/carriers;

% save final results
save([ simulation_name]);

% show results 
marker_style = {'ro-'};
figure(1)
for d=1:length(detector)
    if d==1
        semilogy(SNRdB_range,BER(d,:),marker_style{d},'LineWidth',2)
        hold on
    else
        semilogy(SNRdB_range,BER(d,:),marker_style{d},'LineWidth',2)
    end
end
hold off
grid on
xlabel('Average SNR per receive antenna [dB]','FontSize',12)
ylabel('Bit Error Rate (BER)','FontSize',12)
axis([min(SNRdB_range) max(SNRdB_range) 1e-5 1])
legend(detector,'FontSize',12)
set(gca,'FontSize',12)


%% CG-based MMSE detector
function [idxhat,bithat] = CG_MMSE_detector(H,y,K,symbols,input_bits,N0)
writematrix(H)
writematrix(y)
writematrix(N0)

% A = H'*H + N0 * I  (MMSE matrix)
A = single(H'*H + N0*eye(K,'single'));
b = single(H'*y);

% Conjugate Gradient to solve A x = b
max_iter = 20;      % you can tune this
tol      = 1e-4;    % you can tune this

x = zeros(K,1,'single');   % initial guess
r = b - A*x;
p = r;
rsold = r'*r;

for it = 1:max_iter
    Ap = A*p;
    alpha = rsold / (p'*Ap);
    x = x + alpha*p;
    r = r - alpha*Ap;
    rsnew = r'*r;
    if sqrt(rsnew) < tol
        break;
    end
    p = r + (rsnew/rsold)*p;
    rsold = rsnew;
end

writematrix(x)
xhat = x;

% symbol slicing
[~,idxhat] = min(abs(xhat*ones(1,length(symbols)) - ones(K,1)*symbols).^2,[],2);
bithat = single(input_bits(idxhat,:));
end
