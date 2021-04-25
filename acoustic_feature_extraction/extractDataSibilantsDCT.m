function extractDataSibilantsDCT(subjectFolder)

	content = dir(subjectFolder);
	folderList = content(find(vertcat(content.isdir)));

	for folder = 1:length(folderList)
    
    	phase = folderList(folder).name;
    
    	if strcmp(phase, '.') || strcmp(phase, '..') || strcmp(phase, 'soundcheck') || strcmp(phase, 'testing')
        	continue
    	end

        [fricativeData, ficativeDataMask] = extractFricativePhaseSibilants(subjectFolder, phase);
        saveFricativeSibilantsTable(subjectFolder, fricativeData)

        if ~isempty(ficativeDataMask)
            saveFricativeSibilantsTable(subjectFolder, ficativeDataMask)
        end

        %keyboard
    end
       
end

function [fricativeData, fricativeDataMask] = extractFricativePhaseSibilants(subjectFolder, phase)
    % extract fricative spectral data

    phaseFolder = fullfile(subjectFolder, phase);
    
    fricativeData = {};
    fricativeDataMask = {};

    signal = 'signal';
    signalFolder = fullfile(phaseFolder, signal);

    fileList = dir([signalFolder '\*.mat']);

    for file = 1:length(fileList)

        % set current file name and load the analysis data
        fileName = fileList(file).name;
        
        parameterStruct = loadBoundaries(signalFolder, fileName, phase, 0);
        soundName = parameterStruct.soundName;

        if isfield(parameterStruct, 'fricative')
            % get DCT coeffiecients from the spectrum
            [dctData] = getTrialFricatives(parameterStruct);
            valid = parameterStruct.valid;
        else
            
            dctData = repmat(NaN, 1, 10); % for 10 dct coefficients
            valid = parameterStruct.valid; %set validity to 0?
        end
        
        % trial, index, 10 DCT coeffiecients
        % write the formant vectors to a struct using dynamic expressions (sound names) as field names
        
        if isempty(strfind(fileName, 'masked'))
            try
                if ~isfield(fricativeData, [soundName 'Frication'])
                    fricativeData.(sprintf('%s', [soundName 'Frication'])) = [repmat(file, size(dctData, 1), 1) (1:size(dctData, 1))' repmat(valid, size(dctData, 1), 1) dctData];
                else
                    fricativeData.(sprintf('%s', [soundName 'Frication'])) = ...
                    [fricativeData.(sprintf('%s', [soundName 'Frication'])); [repmat(file, size(dctData, 1), 1) (1:size(dctData, 1))' repmat(valid, size(dctData, 1), 1) dctData]];
                end
            catch
                disp('Make spectrum struct went wrong')
                keyboard
            end
        else
            try
                if ~isfield(fricativeDataMask, [soundName 'Frication'])
                    fricativeDataMask.(sprintf('%s', [soundName 'Frication'])) = [repmat(file, size(dctData, 1), 1) (1:size(dctData, 1))' repmat(valid, size(dctData, 1), 1) dctData];
                else
                    fricativeDataMask.(sprintf('%s', [soundName 'Frication'])) = ...
                    [fricativeDataMask.(sprintf('%s', [soundName 'Frication'])); [repmat(file, size(dctData, 1), 1) (1:size(dctData, 1))' repmat(valid, size(dctData, 1), 1) dctData]];
                end
            catch
                disp('Make spectrum masked struct went wrong')
                keyboard
            end
        end
    end

    fricativeData.phase = phase;

    if ~isempty(fricativeDataMask)
        fricativeDataMask.phase = [phase(1) 'masked'];
    end
end

function [dctData] = getTrialFricatives(parameterStruct)

    signal = parameterStruct.fricative;
    signalShift = parameterStruct.fricativeShift;   

    samplerate = parameterStruct.samplerate;

    % filter specifications for high pass above 600 Hz
    [b, a]= butter(6, 600/(samplerate/2), 'high');

    %% high pass filter original audio and get its intensity via Audapter
    try
        filtSignal = filtfilt(b, a, signal);
        %% high pass filter shifted audio
        filtShift = filtfilt(b, a, signalShift);
    catch
        disp('Too few samples to filter the fricative interval.');
        keyboard
    end

    dctData = computeDCT(signal, signalShift, samplerate);
    dctData = normalizeDCT(dctData);

    %keyboard

end

function [dctData] = computeDCT(signal, signalShift, samplerate);

    % splitting the signal into frames and perform spectral computations
    % window length in samples (value of 256 is taken from Audapter defaults to be consistent?)
    winLength = 256;

    % % following function is part of VOICEBOX
    % % last argument 'p' is chosen to compute power spectra (see documentation for details)
    [frames, ~, ~] = enframe(signal, hamming(winLength, 'periodic'), winLength/4, 'p');
    
    % signal is splitted into 75% overlapping Hamming windows of length winLength
    % power spectrum is computed for each window
    [~, f] = pwelch(signal, hamming(winLength, 'periodic'), winLength/4, [], samplerate);
    
    %plot(f, 10*log10(frames(:,1)), 'k')
    
    % original DCT coefficients for all computed frames
    coefficients = [];
    for frame = 1:size(frames, 1)
        frameCoeff = dct(frames(frame,:));
        coefficients = [coefficients; frameCoeff(1:10)];
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % compute shifted DCT
    % [frames, ~, ~] = enframe(signalShift, hamming(winLength, 'periodic'), winLength/4, 'p');
    
    % % signal is splitted into 75% overlapping Hamming windows of length winLength
    % % power spectrum is computed for each window
    % [~, f] = pwelch(signalShift, hamming(winLength, 'periodic'), winLength/4, [], samplerate);
    
    % %plot(f, 10*log10(frames(:,1)), 'k')

    % % shifted DCT for all computed frames
    % coefficientsShifted = [];
    % for frame = 1:size(frames, 1)
    %     frameCoeff = dct(frames(frame,:));
    %     coefficientsShifted = [coefficientsShifted; frameCoeff(1:10)];
    % end
    
    % combine all vectors into a matrix
    try
        
        dctData = coefficients;
    catch
        disp('Spectral data combination went wrong');
        keyboard
    end

end

function [dctData] = normalizeDCT(dctData);

    % normalizing the spectral vector
    
    lenSpectralVec = size(dctData, 1);

    % length with additional 2 data points
    lenAdd = lenSpectralVec + 2;
                
    resFactor = round(100*lenAdd/lenSpectralVec);
        
    % resample the spectral vectors to ~100 + additional samples
    for f = 1:size(dctData, 2)
        try
            currentVector = resample(dctData(:,f), resFactor, lenSpectralVec);
        catch
            disp('Spectral resampling went wrong');
            keyboard
        end
    
        % compute the number of superfluous samples on each side
        redun = ceil((length(currentVector)-100)/2);

        % choose the ~100 at the center of the array (trimm 1 additional point at the beginning)
        currentVector = currentVector(redun+1:length(currentVector)-(redun-1));
        
        % values missing until 100
        miss = 100-length(currentVector);

        if miss > 0
            % create array with nan's
            nan = NaN(miss);
            % combine the segment with nan
            try
                spectralRes(:,f) = [currentVector; nan];
            catch
                disp('Spectral naning went wrong')
                keyboard
            end
        else
            try
                spectralRes(:,f) = currentVector(1:length(currentVector)+miss);
            catch
                disp('Spectral trimming went wrong')
                keyboard
            end
        end
    end

    %replace the original spectral vectors with normalized
    dctData = spectralRes;

end

function parameterStruct = loadBoundaries(signalFolder, fileName, phase, v)
    
    fileNameCopy = fileName;

    % get gender from the subjectFolder name
    signalFolderCopy = regexp(signalFolder,'\','split');
    gender = signalFolderCopy{5};
    
    % get stimulus name from the file name:
    % sound name is always in the second position trialnumber_soundname_
    loop = 0;
    while 1
        [token, fileNameCopy] = strtok(fileNameCopy, '_');
        loop = loop + 1;
        if loop == 2, break; end
    end

    soundName = token;

    fileNr = strtok(fileName, '_');

    valid = 1; % set every trial valid at first

    % if we are not in the baseline, check the perturbation state for validity
    if isempty(strfind(phase, 'baseline'))

        if isempty(strfind(fileName, 'masked')) && (strcmp(soundName,'vsj') || strcmp(soundName, 'lsj'))

            analysisFolder = strrep(signalFolder, 'signal', 'analysis');
            fileNameAnalysis = strrep(fileName, 'sig', 'ana');

            load(fullfile(analysisFolder, fileNameAnalysis), 'data', 'descriptor');

            %convert the descriptor fields to cell array
            descriptor = cellstr(descriptor);

            ost = 'ost_stat';

            % get the ost states changes
            ostStatus = data(:,find(strcmp(descriptor, ost)));


            if max(ostStatus) < 4
                valid = 0;
            end
            
            if max(ostStatus) > 3
                % get all indexes for fricative
                fricativeState = ostStatus == 4;
                % get the onset and offsets
                fricativeIndexVector = find(fricativeState~=0);

                onsetF = data(fricativeIndexVector(1),1);
                offsetF = data(fricativeIndexVector(end),1);

                fricativeDuration = offsetF-onsetF;

                % if tracked frivative shorter than 90 msec, exclude the shifted trial
                if fricativeDuration < 0.09
                    valid = 0;
                end
            end
        end
    end

    % construct parameterStruct
    parameterStruct.signalFolder = signalFolder;
    parameterStruct.signalFile = fileName;
    parameterStruct.phase = phase;
    parameterStruct.fileNr = fileNr;
    parameterStruct.soundName = soundName;
    % parameterStruct.signalVector = signalVector;
    % parameterStruct.shiftedVector = shiftedVector;
    parameterStruct.gender = gender;
    parameterStruct.valid = valid;

    % load the data and save the signal vector
    if v
        load(fullfile(signalFolder, fileName), 'data', 'vowel', 'samplerate');

        if ~exist('vowel', 'var')
            disp(['Missing vowel in file ' mat2str(fileName(1:4)) ' in ' mat2str(phase)]);
            
            if ((strcmp(phase, '1baseline') && str2double(fileNr) == 50) || str2double(fileNr) == 57 || (strcmp(phase, '5crosseffects') && str2double(fileNr) == 32))
                return
            else
                parameterStruct.samplerate = samplerate;
                parameterStruct.timeFrame = data(:,1)/samplerate;
                [vowel] = graphicBoundariesSet(parameterStruct, 'vowel');
            end
        end
        
        if vowel(2)-vowel(1) < 0.085 || vowel(2)-vowel(1) > 0.55
            disp(['Vowel too short or too long in file ' mat2str(fileName(1:4)) ' in ' mat2str(phase)]);
            %return
            parameterStruct.samplerate = samplerate;
            parameterStruct.timeFrame = data(:,1)/samplerate;
            [vowel] = graphicBoundariesSet(parameterStruct, 'vowel');
        end

        signalVector = double(data(:,1));
    else
        
        load(fullfile(signalFolder, fileName), 'data', 'fricative', 'samplerate');

        if ~exist('fricative', 'var')
            disp(['Missing fricative in file ' mat2str(fileName(1:4)) ' in ' mat2str(phase)]);

            if ((strcmp(phase, '1baseline') && str2double(fileNr) == 50) || str2double(fileNr) == 57 || (strcmp(phase, '5crosseffects') && str2double(fileNr) == 32))
                return
            else
                parameterStruct.samplerate = samplerate;
                parameterStruct.timeFrame = data(:,1)/samplerate;
                [fricative] = graphicBoundariesSet(parameterStruct, 'fricative');
            end
        end

        if fricative(2)-fricative(1) < 0.1 || fricative(2)-fricative(1) > 0.55
            disp(['Fricative too short or too long in file ' mat2str(fileName(1:4)) ' in ' mat2str(phase)]);
            %return
            parameterStruct.samplerate = samplerate;
            parameterStruct.timeFrame = data(:,1)/samplerate;
            [fricative] = graphicBoundariesSet(parameterStruct, 'fricative');
        end
 
        signalVector = double(data(:,1));
        shiftedVector = double(data(:,2));

    end

    if v
        try
            parameterStruct.vowel = signalVector(round(vowel(1)*samplerate):round(vowel(2)*samplerate));
            parameterStruct.duration = vowel(2)-vowel(1);
        catch
            disp('Problem with vowel boundaries');
            keyboard
        end
    else
        try
            parameterStruct.fricative = signalVector(round(fricative(1)*samplerate):round(fricative(2)*samplerate));
            parameterStruct.duration = fricative(2)-fricative(1);
            parameterStruct.fricativeShift = shiftedVector(round(fricative(1)*samplerate):round(fricative(2)*samplerate));
        catch
            disp('Problem with fricative boundaries');
            keyboard
        end
    end
    
    parameterStruct.samplerate = samplerate;
end

function [interval] = graphicBoundariesSet(parameterStruct, soundtype)

        signalFolder = parameterStruct.signalFolder;
        signalFile = parameterStruct.signalFile;
        phase = parameterStruct.phase;
        fileNr = parameterStruct.fileNr;
        soundName = parameterStruct.soundName;
        samplerate = parameterStruct.samplerate;
        timeFrame = parameterStruct.timeFrame;

        load(fullfile(signalFolder, signalFile), 'data');

        signalVector = double(data(:,1));

        purple =  [0.5 0.1 0.5];

        figure('Name', ['Phase ' phase ' file ' fileNr], 'units', 'normalized', 'outerposition', ...
        [0 0 1 1], 'NumberTitle', 'off');
        
        subplot(2,1,1)
        iptsetpref('ImshowBorder','tight');
        title([' Sound ' soundtype ' Response: [' soundName ']'], 'FontSize', 30)
        hold on
        plot(signalVector(1:end-10*5000), 'b');
        set(gca, 'YTick', []);
        set(gca, 'XTick', []);
        axis tight;

        subplot(2,1,2)
        iptsetpref('ImshowBorder','tight');
        spgrambw(signalVector(1:end-10*5000), samplerate, 'i', 400, 15500, 60);
        hold on
        title(['Response: [' soundName ']'], 'FontSize', 30)

        %play sound
        soundsc(signalVector(1:end-(round(length(signalVector)/1.5))), samplerate)

        % input own boundaries
        [inputBoundaries] = ginput(2);
        
        if ~isempty(inputBoundaries)
            interval = [inputBoundaries(1) inputBoundaries(2)];

            % write the boundaries to the signal mat file
            if strcmp(soundtype, 'fricative')
                fricative = interval;
                save(fullfile(signalFolder, signalFile), 'fricative','-append');
            else
                vowel = interval;
                save(fullfile(signalFolder, signalFile), 'vowel','-append');
            end
        else
            close all
            return
        end
        
        close all
end

function saveFricativeSibilantsTable(subjectFolder, segmentData)
    % saves all data to an excel table for further statistical analyses,
    % e.g. with R

    % get subject's name and gender from the subject path
    i = 1;
    while 1
        [str, subjectFolder] = strtok(subjectFolder, '\');
        if isempty(str),  break;  end
        pathInfo{i} = sprintf('%s', str);
        i = i + 1;
    end

    subject = pathInfo{6};
    gender = pathInfo{5};

    % save the experimental phase of the extracted segmentData
    phase = segmentData.phase;

    if strcmp(phase, '1baseline')
        phase = 'baseline';
    elseif strcmp(phase, '2shift')
        phase = 'shift_2';
    elseif strcmp(phase, '2masked')
        phase = 'shift_2_mask';
    elseif strcmp(phase, '3shift')
        phase = 'shift_3';
    elseif strcmp(phase, '3masked')
        phase = 'shift_3_mask';
    elseif strcmp(phase, '4shift')
        phase = 'shift_4';
    elseif strcmp(phase, '4masked')
        phase = 'shift_4_mask';
    elseif strcmp(phase, '5crosseffects')
        phase = 'shift_5_cross';
    end

    outputFile = fullfile(pathInfo{1}, pathInfo{2}, 'data_tables', 'vowilants_dct', ['fricatives_dct_' subject '_' phase '.xlsx']);

    % remove the phase field before looping through the struct
    if isfield(segmentData, 'phase')
        segmentData = rmfield(segmentData, 'phase');
    end

    % get field names
    fields = fieldnames(segmentData);

    %header = {'subject' 'gender' 'phase' 'stimulus' 'trial' 'index' 'valid' 'duration' 'intensity' 'CoG' 'SD' 'skew' 'kurt' 'peakFr' 'lowPeakFr' 'midPeakFr' 'midhighPeakFr' 'highPeakFr' 'diffMidLow' 'diffHighMid' 'diffHighMidRMS' 'CoG_shift' 'SD_shift' 'skew_shift' 'kurt_shift' 'peakFr_shift' 'lowPeakFr_shift' 'midPeakFr_shift' 'midhighPeakFr_shift' 'highPeakFr_shift' 'diffMidLow_shift' 'diffHighMid_shift' 'diffHighMidRMS_shift'};

    header = {'subject' 'gender' 'phase' 'stimulus' 'trial' 'index' 'valid' 'dct_0' 'dct_1' 'dct_2'...
    'dct_3' 'dct_4' 'dct_5' 'dct_6' 'dct_7' 'dct_8' 'dct_9'};

    for snd = 1:length(fields)
        if snd == 1

            try
            sndLables = horzcat(cellstr(repmat([subject '  '], size(eval(['segmentData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([gender '  '], size(eval(['segmentData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([phase '  '], size(eval(['segmentData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([strtok(fields{snd}, 'F') '  '], size(eval(['segmentData.' fields{snd}]), 1), 1)), ...
                        num2cell(eval(['segmentData.' fields{snd}]))); 
            sndLables = vertcat(header, sndLables);
            catch
                disp('Fricatives header fucked up')
                keyboard
            end
        else
            
            sndLables = horzcat(cellstr(repmat([subject '  '], size(eval(['segmentData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([gender '  '], size(eval(['segmentData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([phase '  '], size(eval(['segmentData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([strtok(fields{snd}, 'F') '  '], size(eval(['segmentData.' fields{snd}]), 1), 1)), ...
                        num2cell(eval(['segmentData.' fields{snd}])));
        end

        if ~exist('allLables', 'var')
            allLables = sndLables;
        else
            allLables = [allLables; sndLables];
        end
    end

    %keyboard

    xlswrite(outputFile, allLables);
end