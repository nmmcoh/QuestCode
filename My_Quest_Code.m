clear;
close all;
initialGuess = 10;

UpperLimit = 200;
tGuess = log10(initialGuess/UpperLimit); 
tGuessSd = 0.2;
beta = 10; % slope
delta = 0.001; % lapse rate
gamma = 0; % sucess when guessing
pThreshold=0.5;%0.82
grain=0.01;
dim=500;
plotIt = 0;

q.updatePdf=1; % boolean: 0 for no, 1 for yes
q.warnPdf=1; % boolean
q.normalizePdf=1; % boolean. This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
q.tGuess=tGuess;
q.tGuessSd=tGuessSd;
q.pThreshold=pThreshold;
q.beta=beta;
q.delta=delta;
q.gamma=gamma;
q.grain=grain;
q.dim=dim;

q = QuestRecompute(q);


%%%%%%%%%%%%%%%%%%%%%%

nTrials = 4;

for trial = 1:nTrials
disp(['Try new intensity -> ', num2str(tGuess)]);
disp(['Try new intensity (unlogged) -> ', num2str(((10^tGuess)*200))]);

response = input(['Trial ', num2str(trial), ', go(0)/no go(1) -> ']);

% save data
q.trial_data(trial,:) = [response, ((10^(tGuess))*200)-10, tGuess];

q = QuestUpdate(q, tGuess, response);

tGuess = QuestMean(q);

q=QuestRecompute(q);

end


% 4. Final threshold estimate
q.finalThreshold = ((10^(tGuess))*200)-10; % unlogged and subtract 10 to rescale
disp(['Estimated threshold = ', num2str(q.finalThreshold)]);

% 5. Final 95% CI calculation
q.finalSD = std(q.trial_data(:,2));
SE = q.finalSD/sqrt(40);
q.CI95 = [q.finalThreshold - (1.96 * SE) q.finalThreshold + (1.96 * SE)];











%%%%%%%%%%%%%%%% QUEST FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%



function q = QuestRecompute(q)

    if length(q)>1
	    for i=1:length(q(:))
		    q(i).normalizePdf=0; % any norming must be done across the whole set of pdfs, because it's actually one big multi-dimensional pdf.
		    q(i)=QuestRecompute(q(i));
	    end
	    return
    end

    q.i=-q.dim/2:q.dim/2;
    q.x=q.i*q.grain;
    q.pdf=exp(-0.5*(q.x/q.tGuessSd).^2);
    q.pdf=q.pdf/sum(q.pdf);
    i2=-q.dim:q.dim;
    q.x2=i2*q.grain;
    q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*q.x2)));
    
    index=find(diff(q.p2)); 
    
    q.xThreshold=interp1(q.p2(index),q.x2(index),q.pThreshold);
    
    q.p2=q.delta*q.gamma+(1-q.delta)*(1-(1-q.gamma)*exp(-10.^(q.beta*(q.x2+q.xThreshold))));
    
    q.s2=fliplr([1-q.p2;q.p2]);
    
    if ~isfield(q,'intensity') || ~isfield(q,'response')
        % Preallocate for 10000 trials, keep track of real useful content in
        % q.trialCount. We allocate such large chunks to reduce memory
        % fragmentation that would be caused by growing the arrays one element
        % per trial. Fragmentation has been shown to cause severe out-of-memory
        % problems if one runs many interleaved quests. 10000 trials require/
        % waste about 157 kB of memory, which is basically nothing for today's
        % computers and likely suffices for even the most tortuous experiment.
        q.trialCount = 0;
        q.intensity=zeros(1,10000);
        q.response=zeros(1,10000);
    end
    
    pL=q.p2(1);
    pH=q.p2(end);
    pE=pH*log(pH+eps)-pL*log(pL+eps)+(1-pH+eps)*log(1-pH+eps)-(1-pL+eps)*log(1-pL+eps);
    pE=1/(1+exp(pE/(pL-pH)));
    q.quantileOrder=(pE-pL)/(pH-pL);
    
    for k=1:q.trialCount
	    inten=max(-1e10,min(1e10,q.intensity(k))); % make intensity finite
	    ii=length(q.pdf)+q.i-round((inten-q.tGuess)/q.grain);
	    if ii(1)<1
		    ii=ii+1-ii(1);
	    end
	    if ii(end)>size(q.s2,2)
		    ii=ii+size(q.s2,2)-ii(end);
	    end
	    q.pdf=q.pdf.*q.s2(q.response(k)+1,ii); % 4 ms
	    if q.normalizePdf && mod(k,100)==0
		    q.pdf=q.pdf/sum(q.pdf);	% avoid underflow; keep the pdf normalized	% 3 ms
	    end
    end
    if q.normalizePdf
	    q.pdf=q.pdf/sum(q.pdf);		% keep the pdf normalized	% 3 ms
    end
end



function q = QuestUpdate(q,intensity,response)
if q.updatePdf
	inten=max(-1e10,min(1e10,intensity)); % make intensity finite
	ii=size(q.pdf,2)+q.i-round((inten-q.tGuess)/q.grain);
	if ii(1)<1 || ii(end)>size(q.s2,2)
		if q.warnPdf
			low=(1-size(q.pdf,2)-q.i(1))*q.grain+q.tGuess;
			high=(size(q.s2,2)-size(q.pdf,2)-q.i(end))*q.grain+q.tGuess;
			oldWarning=warning;
			warning('on'); %#ok<WNON> % no backtrace
			warning(sprintf('QuestUpdate: intensity %.3f out of range %.2f to %.2f. Pdf will be inexact. Suggest that you increase "range" in call to QuestCreate.',intensity,low,high)); %#ok<SPWRN>
			warning(oldWarning);
		end
		if ii(1)<1
			ii=ii+1-ii(1);
		else
			ii=ii+size(q.s2,2)-ii(end);
		end
	end
	q.pdf=q.pdf.*q.s2(response+1,ii); % 4 ms
	if q.normalizePdf
		q.pdf=q.pdf/sum(q.pdf);		% keep the pdf normalized	% 3 ms
	end
end

% keep a historical record of the trials
q.trialCount = q.trialCount + 1;
if q.trialCount > length(q.intensity)
    % Out of space in preallocated arrays. Reallocate for additional
    % 10000 trials. We reallocate in large chunks to reduce memory
    % fragmentation.
    q.intensity = [q.intensity, zeros(1,10000)];
    q.response  = [q.response,  zeros(1,10000)];
end

q.intensity(q.trialCount) = intensity;
q.response(q.trialCount)  = response;



end


function t = QuestMean(q)

if length(q)>1
	t=zeros(size(q));
	for i=1:length(q(:))
		t(i)=QuestMean(q(i));
	end
	return
end
t=q.tGuess+sum(q.pdf.*q.x)/sum(q.pdf);	% mean of our pdf
end