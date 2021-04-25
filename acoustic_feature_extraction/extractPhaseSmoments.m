function [smoments] = extractPhaseSmoments(subjectFolder, phase, plots, wmoments, f1, dy, gy)
%extracting spectral moments form mat-signal files from the passed phase
	
	%plots = 1;
	%wmoments = 0;

	phaseFolder = fullfile(subjectFolder, phase);
    
    signal = 'signal';
    signalFolder = fullfile(phaseFolder, signal);

    fileList = dir([signalFolder '\*.mat']);

    % create an empty struct for spectral moments
    %smoments.(sprintf('%s', ['phase' phase])) = {};
    smoments = {};

    % filter specifications for high pass above 500 Hz
    [b, a]= butter(6, 500/(16000/2), 'high');

    % go through each file in the signalFolder folder
    for file = 1:length(fileList)

    	clear burst;

    	% set current file name and load the data
        fileName = fileList(file).name;
        load(fullfile (signalFolder, fileName), 'data', 'samplerate', 'burst');

        if exist('burst', 'var')
        	% get stimulus name and trialNum from the file name:
        	% sound name is always in the second position trialnumber_soundname_
        	loop = 0;
        	while 1
            	[token, fileName] = strtok(fileName, '_');
            	loop = loop + 1;
            	if loop == 2, break; end
        	end
        	soundName{file} = token;
        
        	signalVec = double(data(:,1));
        	signalVec = signalVec(5000:length(signalVec)-50000);

        	%% high pass filter the audio
        	audioFilter = filtfilt(b, a, signalVec);
        	% extract the burst signal
            burstSignal = audioFilter(round(burst(1)*samplerate):round(burst(2)*samplerate));

            if plots
            	% plot spectral slice
            	plotSpectra(burstSignal, samplerate, token, phase, f1, dy, gy)
            end

            if wmoments
            	% get CoG
            	%from Forrest paper hamming 20msec every 10 msec step

            	% get spectrogram and convert it to magnitude spectrum
            	% (cf. http://www.audiocontentanalysis.org/code/audio-features/computefeature/)
            	%burstSpectrum = spectrogram([burstSignal; zeros(4096, 1)], hann(4096, 'periodic'), 2098, 4096, samplerate);
                %burstSpectrum = abs(burstSpectrum)*2/4096;
            	
                %CoG = FeatureSpectralCentroid(burstSpectrum, samplerate);
            	%skew = FeatureSpectralSkewness(burstSpectrum, samplerate);
            	%kurt = FeatureSpectralKurtosis(burstSpectrum, samplerate);

                % get power aka magnitude spectra
                cellObj = {burstSignal, samplerate};
                L = (length(burstSignal)/samplerate)/2;
                [p,f] = ComputeAOS(cellObj, L);

                %[L1,skew,kurt,med,fd] = ComputeCOG(cellObj);
                
                [CoG, skew, kurt] = computeSmoments(p, f, samplerate);
                %keyboard

            	%get means into one vector        		
        		%moments = [round(nanmean(CoG)) round(nanmean(skew)) round(nanmean(kurt))];
                moments = [round(mean(CoG)) mean(skew) mean(kurt)];

        		%keyboard
        		% write the medians to a struct using dynamic expressions (sound names) as field names
        		if ~isfield(smoments, [soundName{file} 'Smoments']) % .(sprintf('%s', ['phase' phase]))
            		smoments.(sprintf('%s', [soundName{file} 'Smoments'])) = [file moments]; % .(sprintf('%s', ['phase' phase]))
        		else
            		smoments.(sprintf('%s', [soundName{file} 'Smoments'])) = ...
            		[smoments.(sprintf('%s', [soundName{file} 'Smoments'])); [file moments]];
        		end
        	end
        end   
    end
    if wmoments
    	smoments.phase = phase;
    end

end