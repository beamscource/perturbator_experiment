function processFricEMA_label(subjectFolder)

    % locate the kinematic data
    C = strsplit(subjectFolder, '\');
    tokens = strsplit(C{5}, '_');
    subjectID = tokens(2);
    kinematicsFolder = fullfile(subjectFolder, ['kinematics_' subjectID{:}]);

	content = dir(subjectFolder);
	folderList = content(find(vertcat(content.isdir)));

    for folder = 1:length(folderList)
    
    	phase = folderList(folder).name;
        
    	if strcmp(phase, '.') | strcmp(phase, '..') | strcmp(phase, 'soundcheck') | strcmp(phase, 'figures') | strfind(phase, 'familiarization')
            continue
    	end

        if strfind(phase, 'kinematics')
            continue
        end

        disp(['Processing ' phase ' phase.'])

        [fricEMAData] = processPhaseFricEMA(subjectFolder, kinematicsFolder, phase);
        saveFricEMATable(subjectFolder, fricEMAData)

        %keyboard
    end
       
end

function [fricEMAData] = processPhaseFricEMA(subjectFolder, kinematicsFolder, phase)
    % extract fricative spectral data

    phaseFolder = fullfile(subjectFolder, phase);
    
    fricEMAData = {};

    signal = 'signal';
    signalFolder = fullfile(phaseFolder, signal);

    fileList = dir([signalFolder '\*.mat']);

    for file = 1:length(fileList)-1 % skip last trial in each phase (empty)

        % set current file name and load the analysis data
        fileName = fileList(file).name;
        fileNr = strtok(fileName, '_');

        disp(['Processing file ' fileNr '.']);

        parameterStruct = getBoundaries(signalFolder, fileName, phase, kinematicsFolder);

        if isempty(parameterStruct)
            continue
        end

        parameterStruct.subjectFolder = subjectFolder;
        parameterStruct.kinematicsFolder = kinematicsFolder;

        %find the delay between Audapter audio and EMA audio
        parameterStruct = matchAudioDelay(parameterStruct);

        if isempty(parameterStruct)
            continue
        end

        % get spectral data from Audapter
        trialAcoustics = getTrialAcoustics(parameterStruct);
        %disp(['Acoustics for file ' fileNr ' extracted.'])
        
        % get kinematic data from EMA
        trialKinematics = getTrialKinematics(parameterStruct);

        %disp(['Kinematics for file ' fileNr ' extracted.'])

        % combine both modalities
        try
            trialData = [trialAcoustics trialKinematics];
        catch
            disp('Acoustic and kinematic data have different dimensions.');
            keyboard
        end
        
        % write the trial data to a struct using dynamic expressions (sound names) as field names
        soundName = parameterStruct.soundName;
        % fileNr = parameterStruct.fileNr;
        
        % fileNr fileName repetion index a_CoG a_SD a_skew a_kurt a_lowMinAmp
        % a_lowPeakFr a_lowPeakAmp a_midPeakFr a_midPeakAmp a_highPeakFr
        % a_highPeakAmp a_diffMidLowMinAmp a_diffMidLowAmp a_diffHighMidAmp
        % a_diffHighLowAmp a_rmsLow a_rmsMid a_rmsHigh a_rmsMidHigh a_diffHighMidRMS
        % a_diffHighLowRMS a_diffMidLowRMS a_diffMidHighLowRMS a_CoG_shift a_SD_shift
        % a_skew_shift a_kurt_shift a_lowMinAmp_shift a_lowPeakFr_shift
        % a_lowPeakAmp_shift a_midPeakFr_shift a_midPeakAmp_shift a_highPeakFr_shift
        % a_highPeakAmp_shift a_diffMidLowMinAmp_shift a_diffMidLowAmp_shift
        % a_diffHighMidAmp_shift a_diffHighLowAmp_shift a_rmsLow_shift a_rmsMid_shift
        % a_rmsHigh_shift a_rmsMidHigh_shift a_diffHighMidRMS_shift
        % a_diffHighLowRMS_shift a_diffMidLowRMS_shift a_diffMidHighLowRMS_shift
        % k_TB_x k_TB_y k_TB_z k_TM_x k_TM_y k_TM_z k_TT_x k_TT_y k_TT_z k_JAW_x
        % k_JAW_y k_JAW_z

        try
            if ~isfield(fricEMAData, [soundName 'Frication'])
                fricEMAData.(sprintf('%s', [soundName 'Frication'])) = [repmat(file-1, size(trialData, 1), 1) repmat(str2num(fileNr), size(trialData, 1), 1) trialData];
            else
                fricEMAData.(sprintf('%s', [soundName 'Frication'])) = ...
                [fricEMAData.(sprintf('%s', [soundName 'Frication'])); [repmat(file-1, size(trialData, 1), 1) repmat(str2num(fileNr), size(trialData, 1), 1) trialData]];
            end
        catch
            disp('Make data struct went wrong.')
            keyboard
        end
        
        %keyboard
    end

    fricEMAData.phase = phase;
end

function parameterStruct = getBoundaries(signalFolder, fileName, phase, kinematicsFolder)
    
    fileNameCopy = fileName;
    
    % get stimulus name from the file name:
    % sound name is always in the second position trialnumber_soundname_
    loop = 0;
    while 1
        [token, fileNameCopy] = strtok(fileNameCopy, '_');
        loop = loop + 1;
        if loop == 2, break; end
    end

    soundName = token;

    % to skip task description trials
    if isempty(strfind(soundName, 'ls'))
        disp('Task description skipped.')
        parameterStruct = [];
        return
    end

    fileNr = strtok(fileName, '_');

    % get the grid file containing time stamps
    gridsFolder = fullfile(kinematicsFolder, 'wav');
    gridFile = [gridsFolder '\' fileNr '.TextGrid'];

    % read the grid file
    fileID = fopen(gridFile);
    gridText = [];
    currentLine = fgetl(fileID);

    while ischar(currentLine)
        gridText{end+1, 1} = currentLine;
        currentLine = fgetl(fileID);
    end

    fclose(fileID);

    % skip files with less than 2 tiers
    if ~strcmp(strtrim(gridText{7}), 'size = 2')
        disp(['Not enough tiers in grid ' fileNr ' for ' kinematicsFolder]);
        parameterStruct = [];
        return
    end

    onsetF1 = str2num(strtok(gridText{19}, 'number ='));
    offsetF1 = str2num(strtok(gridText{22}, 'number ='));

    onsetF2 = str2num(strtok(gridText{34}, 'number ='));
    offsetF2 = str2num(strtok(gridText{37}, 'number ='));

    intervalF1 = [onsetF1 offsetF1];
    intervalF2 = [onsetF2 offsetF2];

    timeStampsFricatives.intervalF1 = intervalF1;
    timeStampsFricatives.intervalF2 = intervalF2;

    % construct parameterStruct for the trial to extract its data
    parameterStruct.signalFolder = signalFolder;
    parameterStruct.signalFile = fileName;
    parameterStruct.phase = phase;
    parameterStruct.fileNr = fileNr;
    parameterStruct.soundName = soundName;
    parameterStruct.timeStampsFricatives = timeStampsFricatives;
    %keyboard

end

function [parameterStruct] = matchAudioDelay(parameterStruct)
    
    signalFolder = parameterStruct.signalFolder;
    signalFile = parameterStruct.signalFile;
    fileNr = parameterStruct.fileNr;
    kinematicsFolder = parameterStruct.kinematicsFolder;

    emaAudioFolder = fullfile(kinematicsFolder, 'wav');
    
    % load the acoustic data from Audapter
    load(fullfile(signalFolder, signalFile), 'data', 'samplerate');

    audapterSamplerate = samplerate;
    signalAudapter = data(:,1);

    % load acoustic data from EMA
    [emaAudio, emaSamplerate] = audioread(fullfile(emaAudioFolder, [fileNr '.wav']));

    % resample ema audio to match Audapter's signal
    [P, Q] = rat(audapterSamplerate/emaSamplerate);
    signalEMA = resample(emaAudio, P, Q);

    % get the lag between the two signals
    try
        [acor, lag] = xcorr(signalAudapter, signalEMA);
        [~, I] = max(abs(acor));
        lagDiff = lag(I);
    catch
        disp('Problem to correlate audio signals.')
        parameterStruct = [];
        return
    end

    % convert lag to time delay in ms
    timeDiff = lagDiff/audapterSamplerate;

    % add timeDiff to EMA time staps to get Audapter's audio
    parameterStruct.timeStampsFricatives.intervalF1_audapter = parameterStruct.timeStampsFricatives.intervalF1 + timeDiff;
    parameterStruct.timeStampsFricatives.intervalF2_audapter = parameterStruct.timeStampsFricatives.intervalF2 + timeDiff;
    parameterStruct.samplerate = samplerate;
end

function trialAcoustics = getTrialAcoustics(parameterStruct)

    signalFolder = parameterStruct.signalFolder;
    signalFile = parameterStruct.signalFile;
    samplerate = parameterStruct.samplerate;
    timeStampsFricatives = parameterStruct.timeStampsFricatives;

    % load the acoustic data from Audapter
    load(fullfile(signalFolder, signalFile), 'data');

    signal = double(data(:,1));
    signalShift = double(data(:,2));

    % filter specifications for high pass above 600 Hz
    [b, a]= butter(6, 600/(samplerate/2), 'high');

    %% high pass filter Audapter audio
    try
        filtSignal = filtfilt(b, a, signal);
        %% high pass filter shifted audio
        filtShift = filtfilt(b, a, signalShift);
    catch
        disp('Too few samples to filter the signal.');
        keyboard
    end

    try
        filtFricative1 = filtSignal(round(timeStampsFricatives.intervalF1_audapter(1)*samplerate):round(timeStampsFricatives.intervalF1_audapter(2)*samplerate));
        filtFricative1Shift = filtShift(round(timeStampsFricatives.intervalF1_audapter(1)*samplerate):round(timeStampsFricatives.intervalF1_audapter(2)*samplerate));
        filtFricative2 = filtSignal(round(timeStampsFricatives.intervalF2_audapter(1)*samplerate):round(timeStampsFricatives.intervalF2_audapter(2)*samplerate));
    catch
        disp('Not able to chop the signal. Missing boundaries.');
        trialAcoustics = NaN(2,47);
        return
    end
    % disp('Audapter signal filtered and chopped.')
    % keyboard

    spectralDataFric1 = computeSpectrum(filtFricative1, samplerate);
    spectralDataFric1Shift = computeSpectrum(filtFricative1Shift, samplerate);
    spectralDataFric2 = computeSpectrum(filtFricative2, samplerate);
    spectralDataFric2Shift = NaN(size(spectralDataFric2, 1), size(spectralDataFric2, 2));

    % disp('Spectral data computed for each signal portion.')
    % keyboard

    % combine spectral data
    token1 = [spectralDataFric1 spectralDataFric1Shift];
    token2 = [spectralDataFric2 spectralDataFric2Shift];

    durationToken1 = timeStampsFricatives.intervalF1(2)-timeStampsFricatives.intervalF1(1);
    durationToken2 = timeStampsFricatives.intervalF2(2)-timeStampsFricatives.intervalF2(1);

    %add duration to spectral data
    token1 = [repmat(durationToken1, size(token1, 1), 1) token1];
    token2 = [repmat(durationToken2, size(token2, 1), 1) token2];

    % add leading column for sample index
    token1 = [(1:size(token1, 1))' token1];
    token2 = [(1:size(token2, 1))' token2];

    % add leading column for [s] repetion (essentially perturbation condition)
    token1 = [repmat(1, size(token1, 1), 1) token1];
    token2 = [repmat(2, size(token2, 1), 1) token2];

    trialAcoustics = [token1; token2];

    % disp('Spectral data combined.')
    % keyboard

end

function [spectralData] = computeSpectrum(signal, samplerate)

    winLength = 256;
    
    % compute CoG
    [frames, ~, ~] = enframe(signal, hamming(winLength, 'periodic'), winLength/4, 'p');
    
    % signal is splitted into 75% overlapping Hamming windows of length winLength
    % power spectrum is computed for each window
    [~, f] = pwelch(signal, hamming(winLength, 'periodic'), winLength/4, [], samplerate);

    %plot(f, 10*log10(density))

    % define frequency regions (low, mid, mid-high, high) (cf. Koenig et al. 2013)
    boundaryIndx0 = find(f==625);
    boundaryIndx1 = find(f==5500); %3000
    boundaryIndx2 = find(f==11000); %7000
    %boundaryIndx3 = find(f==12000);
    
    % original CoG for all computed frames
    for frame = 1:size(frames, 1)
        [CoG(frame), SD(frame), skew(frame), ~] = getcog(f, frames(frame,:));
    end

    % original peak frequency for the whole spectrum (not in Koenig et al. 2013)
    % for frame = 1:size(frames, 1)
    %     currentFrame = frames(frame,:);
    %     [~, peakFrInx] = min(abs(10*log10(currentFrame)));
    %     peakFr(frame) = f(peakFrInx);
    % end
    
    % original low region min for all frames
    for frame = 1:size(frames, 1)
        currentFrame = frames(frame,:);
        [ampValue, peakFrInx] = min(10*log10(currentFrame(boundaryIndx0:boundaryIndx1-1)));
        lowMinAmp(frame) = ampValue;
        %lowMinFr(frame) = f(peakFrInx+boundaryIndx0-1);
    end

    % original low region peak frequency (not in Koenig)
    % for frame = 1:size(frames, 1)
    %     currentFrame = frames(frame,:);
    %     [ampValue, peakFrInx] = max(10*log10(currentFrame(boundaryIndx0:boundaryIndx1-1)));
    %     lowPeakAmp(frame) = ampValue;
    %     lowPeakFr(frame) = f(peakFrInx+boundaryIndx0-1);
    % end

    % original mid region peak for all frames
    for frame = 1:size(frames, 1)
        currentFrame = frames(frame,:);
        [ampValue, peakFrInx] = max(10*log10(currentFrame(boundaryIndx1:boundaryIndx2-1)));
        midPeakAmp(frame) = ampValue;
        midPeakFr(frame) = f(peakFrInx+boundaryIndx1-1);
    end

    % original mid-high region peak for all frames (high in Koenig et al. 2013)
    for frame = 1:size(frames, 1)
        currentFrame = frames(frame,:);
        [ampValue, peakFrInx] = max(10*log10(currentFrame(boundaryIndx2:end)));
        highPeakAmp(frame) = ampValue;
        %highPeakFr(frame) = f(peakFrInx+boundaryIndx2-1);
    end

    % original high region peak for all frames (above 12000 - not in Koenig et al. 2013)
    % for frame = 1:size(frames, 1)
    %     currentFrame = frames(frame,:);
    %     [~, peakFrInx] = max(10*log10(currentFrame(boundaryIndx3:end)));
    %     highPeakFr(frame) = f(peakFrInx+boundaryIndx3-1);
    % end

    % get differencies between mid-frequency amplitudes and level of low and mid-high tiers
    diffMidLowMinAmp = midPeakAmp - lowMinAmp; %(dB)
    diffHighMidAmp = highPeakAmp - midPeakAmp;
    %diffHighLowAmp = highPeakAmp - lowPeakAmp;
    %diffMidLowAmp = midPeakAmp - lowPeakAmp;

    % get differencies between the levels of mid and mid-high tiers
    % get average intensity levels for mid and high region 
    for frame = 1:size(frames, 1)
        currentFrame = frames(frame,:);
        rmsLow(frame) = 10*log10(rms(currentFrame(boundaryIndx0:boundaryIndx1-1)));
    end

    for frame = 1:size(frames, 1)
        currentFrame = frames(frame,:);
        rmsMid(frame) = 10*log10(rms(currentFrame(boundaryIndx1:boundaryIndx2-1)));
    end

    % original mid-high region level for all frames
    for frame = 1:size(frames, 1)
        currentFrame = frames(frame,:);
        rmsHigh(frame) = 10*log10(rms(currentFrame(boundaryIndx2:end)));
    end

    % original high region level for all frames
    % for frame = 1:size(frames, 1)
    %     currentFrame = frames(frame,:);
    %     rmsMidHigh(frame) = 10*log10(rms(currentFrame(boundaryIndx1:end)));
    % end

    diffHighMidRMS = rmsHigh-rmsMid;
    %diffHighLowRMS = rmsHigh-rmsLow;
    diffMidLowRMS = rmsMid-rmsLow;
    %diffMidHighLowRMS = rmsMidHigh-rmsLow;

    % combine all vectors into a matrix
    try
        % long version (23 parameters)
        % spectralData = [CoG' SD' skew' kurt' lowMinAmp' lowPeakFr' lowPeakAmp' midPeakFr' midPeakAmp' highPeakFr' highPeakAmp' ...
        % diffMidLowMinAmp' diffMidLowAmp' diffHighMidAmp' diffHighLowAmp' rmsLow' rmsMid' rmsHigh' rmsMidHigh' diffHighMidRMS' ...
        % diffHighLowRMS' diffMidLowRMS' diffMidHighLowRMS'];

        spectralData = [CoG' SD' skew' midPeakFr' diffMidLowMinAmp' ...
            diffHighMidAmp' rmsLow' rmsMid' rmsHigh' diffHighMidRMS' ...
            diffMidLowRMS'];

    catch
        disp('Spectral data combination went wrong');
        keyboard
    end

    % normalizing the spectral vector
    lenSpectralVec = size(spectralData, 1);

    % length with additional 2 data points
    lenAdd = lenSpectralVec + 2;
                
    resFactor = round(40*lenAdd/lenSpectralVec);
        
    % resample the spectral vectors to ~40 + additional samples
    for f = 1:size(spectralData, 2)
        
        try
            currentVector = resample(spectralData(:,f), resFactor, lenSpectralVec);
        catch
            disp('Spectral resampling went wrong');
            keyboard
        end
    
        % compute the number of superfluous samples on each side
        redun = ceil((length(currentVector)-40)/2);

        % choose the ~40 at the center of the array (trimm 1 additional point at the beginning)
        currentVector = currentVector(redun+1:length(currentVector)-(redun-1));
        
        % values missing until 40
        miss = 40-length(currentVector);

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
    spectralData = spectralRes;

end

function trialKinematics = getTrialKinematics(parameterStruct)

    kinematicsFolder = parameterStruct.kinematicsFolder;
    timeStampsFricatives = parameterStruct.timeStampsFricatives;
    fileNr = parameterStruct.fileNr;

    C = strsplit(kinematicsFolder, '\');
    tokens = strsplit(C{5}, '_');
    subjectID = tokens(2);

    % subfolder with positional data
    positionsFolder = fullfile(kinematicsFolder, 'pos');
    
    % load position data: 3D matrix with samples*coordinate*sensor
    load(fullfile(positionsFolder, [fileNr '.mat']), 'data', 'samplerate');

    % convert time stamps into samples
    intervalF1 = round(timeStampsFricatives.intervalF1*samplerate);
    intervalF2 = round(timeStampsFricatives.intervalF2*samplerate);
    
    % 4 = TB, 5 = TM, 6 = TT, 8 = JAW, 9 = UL, 10 = LL
    switch subjectID{:}
        case 'imke'
            sensorList = [4 11 6 8 9 10];
        case 'julia'
            sensorList = [12 5 6 8 11 10];
        otherwise
            sensorList = [4 5 6 8 9 10]; % default
    end
    
    % 1 = X (left-right), 2 = Y (anterior-posterior), 3 = Z (bottom-down)
    dimensionList = [1 2 3];

    loopRun = 0;

    for sensor = sensorList

    
        for dim = dimensionList
            % count number of times a parameter was extracted
            loopRun = loopRun+1;

            try
                token1(:,loopRun) = data(intervalF1(1):intervalF1(2), dim, sensor);
                token2(:,loopRun) = data(intervalF2(1):intervalF2(2), dim, sensor);
            catch
                disp(['Problem accessing articulatory data in ' fileNr ', ' num2str(sensor) '.'])
                
                token1(:,loopRun) = NaN(size(data(intervalF1(1):intervalF1(2)), 2), 1);
                token2(:,loopRun) = NaN(size(data(intervalF2(1):intervalF2(2)), 2), 1);

                % trialKinematics = NaN(2, length(sensorList)*length(dimensionList));
                % return
            end
        end
    end

    token1 = normalizeKinematics(token1);
    token2 = normalizeKinematics(token2);

    %combine both [s] repetitions
    trialKinematics = [token1; token2];

    %keyboard

end

function kinematicRes = normalizeKinematics(kinematicsData)

    % normalizing the kineatic vector
    lenKinematicVec = size(kinematicsData, 1);

    % length with additional 2 data points
    lenAdd = lenKinematicVec + 2;
                
    resFactor = round(40*lenAdd/lenKinematicVec);
        
    % resample the spectral vectors to ~40 + additional samples
    for f = 1:size(kinematicsData, 2)
        
        try
            currentVector = resample(kinematicsData(:,f), resFactor, lenKinematicVec);
        catch
            disp('Kinematic resampling went wrong');
            keyboard
        end
    
        % compute the number of superfluous samples on each side
        redun = ceil((length(currentVector)-40)/2);

        % choose the ~40 at the center of the array (trimm 1 additional point at the beginning)
        currentVector = currentVector(redun+1:length(currentVector)-(redun-1));
        
        % values missing until 40
        miss = 40-length(currentVector);

        if miss > 0
            % create array with nan's
            nan = NaN(miss);
            % combine the segment with nan
            try
                kinematicRes(:,f) = [currentVector; nan];
            catch
                disp('Kinematic naning went wrong')
                keyboard
            end
        else
            try
                kinematicRes(:,f) = currentVector(1:length(currentVector)+miss);
            catch
                disp('Kinematic trimming went wrong')
                keyboard
            end
        end
    end
end

function saveFricEMATable(subjectFolder, fricEMAData)
    % saves all data to an excel table for further statistical analyses,
    % e.g. with R

    % get subject's name
    i = 1;
    while 1
        [str, subjectFolder] = strtok(subjectFolder, '\');
        if isempty(str),  break;  end
        pathInfo{i} = sprintf('%s', str);
        i = i + 1;
    end

    subject = pathInfo{5};
    subject = strsplit(subject, 'fricEMA_');
    subject = subject{2};

    % save the experimental phase of the extracted fricEMAData
    phase = fricEMAData.phase;

    %rename phases
    numPhase = phase(1);
    namePhase = phase(2:end);

    if strcmp(namePhase, 'baseline')
        phase = namePhase;
    else
        phase = [namePhase '_' numPhase];
    end

    outputFile = fullfile(pathInfo{1}, pathInfo{2}, 'data_tables', 'fricEMA_label', ['fricatives_fricEMA_label_' subject '_' phase '.xlsx']);

    % remove the phase field before looping through the struct
    if isfield(fricEMAData, 'phase')
        fricEMAData = rmfield(fricEMAData, 'phase');
    end

    % get field names
    fields = fieldnames(fricEMAData);

    % full version with 23 acoustic parameters
    % header = {'subject' 'phase' 'stimulus' 'fileNr' 'fileName' 'repetion' 'index'
    %     'duration' 'a_CoG' 'a_SD' 'a_skew' 'a_kurt' ...
    %     'a_lowMinAmp' 'a_lowPeakFr' 'a_lowPeakAmp' 'a_midPeakFr' 'a_midPeakAmp' ...
    %     'a_highPeakFr' 'a_highPeakAmp' 'a_diffMidLowMinAmp' 'a_diffMidLowAmp' ...
    %     'a_diffHighMidAmp' 'a_diffHighLowAmp' 'a_rmsLow' 'a_rmsMid' 'a_rmsHigh' ...
    %     'a_rmsMidHigh' 'a_diffHighMidRMS' 'a_diffHighLowRMS' 'a_diffMidLowRMS' ...
    %     'a_diffMidHighLowRMS' 'a_CoG_shift' 'a_SD_shift' 'a_skew_shift' ...
    %     'a_kurt_shift' 'a_lowMinAmp_shift' 'a_lowPeakFr_shift' 'a_lowPeakAmp_shift' ...
    %     'a_midPeakFr_shift' 'a_midPeakAmp_shift' 'a_highPeakFr_shift' ...
    %     'a_highPeakAmp_shift' 'a_diffMidLowMinAmp_shift' 'a_diffMidLowAmp_shift' ...
    %     'a_diffHighMidAmp_shift' 'a_diffHighLowAmp_shift' 'a_rmsLow_shift' ...
    %     'a_rmsMid_shift' 'a_rmsHigh_shift' 'a_rmsMidHigh_shift' ...
    %     'a_diffHighMidRMS_shift' 'a_diffHighLowRMS_shift' 'a_diffMidLowRMS_shift' ...
    %     'a_diffMidHighLowRMS_shift' 'k_TB_x' 'k_TB_y' 'k_TB_z' 'k_TM_x' 'k_TM_y' ...
    %     'k_TM_z' 'k_TT_x' 'k_TT_y' 'k_TT_z' 'k_JAW_x' 'k_JAW_y' 'k_JAW_z'};

    % short verion with 11 acoustic parameters but with upper and lower lip
    header = {'subject' 'phase' 'stimulus' 'fileNr' 'fileName' 'repetion' 'index'...
            'duration' 'a_CoG' 'a_SD' 'a_skew' 'a_midPeakFr' 'a_diffMidLowMinAmp'...
            'a_diffHighMidAmp' 'a_rmsLow' 'a_rmsMid' 'a_rmsHigh' 'a_diffHighMidRMS'...
            'a_diffMidLowRMS' 'a_CoG_shift' 'a_SD_shift' 'a_skew_shift'...
            'a_midPeakFr_shift' 'a_diffMidLowMinAmp_shift' 'a_diffHighMidAmp_shift'...
            'a_rmsLow_shift' 'a_rmsMid_shift' 'a_rmsHigh_shift' 'a_diffHighMidRMS_shift'...
            'a_diffMidLowRMS_shift' 'k_TB_x' 'k_TB_y' 'k_TB_z' 'k_TM_x' 'k_TM_y' 'k_TM_z'...
            'k_TT_x' 'k_TT_y' 'k_TT_z' 'k_JAW_x' 'k_JAW_y' 'k_JAW_z' 'k_UL_x' 'k_UL_y'...
            'k_UL_z' 'k_LL_x' 'k_LL_y' 'k_LL_z'};

    for snd = 1:length(fields)
        if snd == 1

            try
            sndLables = horzcat(cellstr(repmat([subject '  '], size(eval(['fricEMAData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([phase '  '], size(eval(['fricEMAData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([strtok(fields{snd}, 'F') '  '], size(eval(['fricEMAData.' fields{snd}]), 1), 1)), ...
                        num2cell(eval(['fricEMAData.' fields{snd}]))); 
            sndLables = vertcat(header, sndLables);
            catch
                disp('Fricatives header fucked up')
                keyboard
            end
        else
            
            sndLables = horzcat(cellstr(repmat([subject '  '], size(eval(['fricEMAData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([phase '  '], size(eval(['fricEMAData.' fields{snd}]), 1), 1)), ...
                        cellstr(repmat([strtok(fields{snd}, 'F') '  '], size(eval(['fricEMAData.' fields{snd}]), 1), 1)), ...
                        num2cell(eval(['fricEMAData.' fields{snd}])));
        end

        if ~exist('allLables', 'var')
            allLables = sndLables;
        else
            allLables = [allLables; sndLables];
        end
    end

    %keyboard

    try
        xlswrite(outputFile, allLables);
        %disp([phase ' data saved to disk.'])
    catch
        disp(['Problem with writing ' phase ' data to disk.'])
        keyboard
    end
end