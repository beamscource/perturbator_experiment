function textGridization(subjectFolder)

    % locate the kinematic data
    C = strsplit(subjectFolder, '\');
    tokens = strsplit(C{5}, '_');
    subjectID = tokens(2);
    kinematicsFolder = fullfile(subjectFolder, ['kinematics_' subjectID{:}]);

	content = dir(subjectFolder);
	folderList = content(find(vertcat(content.isdir)));

    for folder = 1:length(folderList)
    
    	phase = folderList(folder).name;
        
    	if strcmp(phase, '.') | strcmp(phase, '..') | strcmp(phase, 'soundcheck') | strcmp(phase, 'figures')
            continue
    	end

        if strfind(phase, 'kinematics')
            continue
        end

        disp(['Processing ' phase ' phase.'])

        processPhaseFricEMA(subjectFolder, kinematicsFolder, phase, 1);

        %keyboard
    end
       
end

function processPhaseFricEMA(subjectFolder, kinematicsFolder, phase, gCheck)
    % extract fricative spectral data

    phaseFolder = fullfile(subjectFolder, phase);

    signal = 'signal';
    signalFolder = fullfile(phaseFolder, signal);

    fileList = dir([signalFolder '\*.mat']);

    for file = 2:length(fileList)-1 % skip first and last trial in each phase (empty)

        % set current file name and load the analysis data
        fileName = fileList(file).name;
        fileNr = strtok(fileName, '_');

        disp(['Processing file ' fileNr '.'])

        if strfind(phase, 'familiarization')
            writeTextGrid(kinematicsFolder, fileNr, 1);
            continue
        end

        [parameterStruct, taskDescription] = getBoundaries(signalFolder, fileName, phase, gCheck);

        if isempty(parameterStruct) & ~taskDescription
            writeTextGrid(kinematicsFolder, fileNr, 0);
            continue
        end

        parameterStruct.subjectFolder = subjectFolder;
        parameterStruct.kinematicsFolder = kinematicsFolder;

        %find the delay between Audapter audio and EMA audio
        parameterStruct = matchAudioKinematics(parameterStruct);
        writeTextGrid(parameterStruct, [], []);
       
        
        %keyboard
    end


end

function [parameterStruct, taskDescription] = getBoundaries(signalFolder, fileName, phase, gCheck)
    
    taskDescription = 0;

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
        taskDescription = 1;
        return
    end

    fileNr = strtok(fileName, '_');

    % for skipping certain files
    % if str2num(fileNr) == 38
    %     parameterStruct = [];
    %     disp('File 38 skipped.')
    %     return
    % end

    %load the analysis data for the trial
    analysisFolder = strrep(signalFolder, 'signal', 'analysis');
    fileNameAnalysis = strrep(fileName, 'sig', 'ana');

    load(fullfile(analysisFolder, fileNameAnalysis), 'data', 'descriptor', 'samplerate');

    %convert the descriptor fields to cell array
    descriptor = cellstr(descriptor);
    
    % get the column with ost values
    ost = 'ost_stat';
    ostStatus = data(:,find(strcmp(descriptor, ost)));

    %get frame time
    timeFrame = data(:,1);

    pertValid = 1; % set every trial valid at first

    % end of the fricative was not detected
    if max(ostStatus) < 4
        
        onsetOstF = NaN;
        offsetOstF = NaN;
        ostTimeStamps.onsetOstF = onsetOstF;
        ostTimeStamps.offsetOstF = offsetOstF;
        fricativeDuration = offsetOstF-onsetOstF;

        % if we are in a shift phase, check the perturbation state for validity
        if strfind(phase, 'shift')
            pertValid = 0;
        end
    else
        % get all indexes for fricative
        fricativeState = ostStatus == 4;
        
        if any(fricativeState)

            % get the onset and offsets
            fricativeIndexVector = find(fricativeState~=0);

            % get the duration of the interval in sec 
            onsetOstF = data(fricativeIndexVector(1), 1);
            offsetOstF = data(fricativeIndexVector(end), 1);
            ostTimeStamps.onsetOstF = onsetOstF;
            ostTimeStamps.offsetOstF = offsetOstF;
            fricativeDuration = offsetOstF-onsetOstF;
        else
            % get default (essentially 0) duration 
            onsetOstF = data(1, 1);
            offsetOstF = data(2, 1);
            ostTimeStamps.onsetOstF = onsetOstF;
            ostTimeStamps.offsetOstF = offsetOstF;
            fricativeDuration = offsetOstF-onsetOstF;
            disp('OST tracking data faulty. Possible Audapter crash.')
            parameterStruct = [];
            return
        end

        % if tracked frivative shorter than 90 msec (foul tracking),
        % set the trial to non-valid
        if fricativeDuration < 0.06
            %if strfind(phase, 'shift')
                pertValid = 0;
            %end
        end
    end

    % get rms curves
    rmsCurvePre = data(:,3);
    rmsCurveSmooth = data(:,2);
    rmsRatio = 1./(rmsCurveSmooth./rmsCurvePre);
    rmsRatio = rmsRatio/8.5; % scaling for plotting
    
    %smooth the rmsRatio curve
    rmsRatioSmooth = smooth(rmsRatio, 0.03, 'rloess');
    rmsLevel = max(rmsRatioSmooth)/2;

    %zerro-crossing function
    zci = @(v) find(v(:).*circshift(v(:), [-1 0]) <= 0);

    % define a threshold for zero-crossing
    threshold = 0.11; % normal threshold = 0.11; 
    % threshold = rmsLevel/2*1.6;
    % thresholdLow = threshold*0.8;

    sibilantBounds = [];

    iterations = 0;

    %method flag: zero-crossings or peaks
    method = 1; % for zero-crossing

    % try to find two intervals
    while length(sibilantBounds) < 4

        disp('Found less than two intervals. Decreasing threshold.')
        threshold = threshold - 0.005;
        
        % find zero-crossing indices
        zx = zci(rmsRatioSmooth - threshold);

        sibilantBounds = timeFrame(zx);

        iterations = iterations + 1;

        if iterations == 100
            %disp('Max number of iterations with zero-crossing reached.')
            break
        end

        if threshold < 0.095 %thresholdLow
            disp('Max number of iterations with zero-crossing reached due too low threshold.')
            method = 0; %for peak finding
            break
        end
    end

    disp(['Zero-crossing found ' num2str(length(sibilantBounds)/2) ' intervals.'])

    iterations2 = 0;
    durationFlag = 1;
    distanceFlag = 1;
    similarityFlag = 1;
    
    % perform additional checks, if neccessary to break down to two intervals
    while length(sibilantBounds) >= 4

        iterations2 = iterations2 + 1;

        if iterations2 == 1

            %disp('Check interval durations.')
                
            % difine time limits for sibilants (get wider as threshold decreases)
            % if zero-crossings fail too much, redefine constants 
            lowerBound = 0.005/threshold; % ~ 50 ms;
            upperBound = 0.012/threshold; % ~ 100 ms

            % get interval durations
            durations = [];
            loopRun = 0;
            for i = 1:2:length(sibilantBounds)
                loopRun = loopRun + 1;
                durations(loopRun) = sibilantBounds(i+1) - sibilantBounds(i);
            end

            % delete itervals which are too long or too short
            sibilantBoundsDelete = [];
            loopRun = 0;
                
            for i = 1:length(durations)

                loopRun = loopRun + 1;

                if ~(durations(loopRun) > lowerBound & durations(loopRun) < upperBound)
                    sibilantBoundsDelete = [sibilantBoundsDelete sibilantBounds([(loopRun*2-1) (loopRun*2)])]; %(i-1)*2+1 / %(i-1)*2+2
                end
            end

            %keyboard
            sibilantBoundsDurations = sibilantBounds;

            if length(sibilantBoundsDelete) > 0

                for i = 1:length(sibilantBoundsDelete)
                    sibilantBoundsDurations = sibilantBoundsDurations(find(sibilantBoundsDurations ~= sibilantBoundsDelete(i)));
                end
            end

            % set check flag
            if length(sibilantBoundsDurations) ~= 4
                %disp('Duration check failed.')
                durationFlag = 0;
            else
                %disp('Duration check successfull.')
            end

            if length(sibilantBoundsDurations) < 4
                method=0; % for peak finding
            end

            sibilantBounds = sibilantBoundsDurations;
        end

        if iterations2 == 2

            %disp('Check for the time interval between the peaks.')

            % define interval centers in ms
            sibilants = [];
            loopRun = 0;
            
            % protect against odd number of bounds
            if mod(length(sibilantBounds), 2)
                sibilantBounds = sibilantBounds(1:end-1);
            end

            for i = 1:2:length(sibilantBounds)
                loopRun = loopRun + 1;
                sibilants(loopRun) = sibilantBounds(i) + ((sibilantBounds(i+1)-sibilantBounds(i))/2);
            end

            % define min and max distances allowed between two intervals
            minDistance = 0.075;
            maxDistance = 1.3;
            % normal values
            % minDistance = 0.075;
            % maxDistance = 1.7;

            sibilantBoundsDistance = [];

            % loop through all sibilants
            for i = 1:length(sibilants)-1 %don't check the last sibilant

                currentSibilant = sibilants(i);

                % compare current sibilant to all remaining
                for j = i+1:length(sibilants)

                    if ~(sibilants(j)-currentSibilant < minDistance) | ~(sibilants(j)-currentSibilant > maxDistance)
                        sibilantBoundsDistance = [sibilantBoundsDistance sibilantBounds(i*2-1) sibilantBounds(i*2)];
                        sibilantBoundsDistance = [sibilantBoundsDistance sibilantBounds(j*2-1) sibilantBounds(j*2)];
                        % if str2num(fileNr) == 61
                        %     disp('Inside distance loop.')
                        %     keyboard
                        % end
                    end
                end

                sibilantBoundsDistance = unique(sibilantBoundsDistance);
            end

            % transform
            sibilantBoundsDistance = sibilantBoundsDistance';

            % set check flag
            if length(sibilantBoundsDistance) ~= 4
                %disp('Distance check failed.')
                distanceFlag = 0;
            else
                %disp('Distance check successfull.')
            end

            if length(sibilantBoundsDistance) < 4
                method=0; % for peak finding    
            end
            
            sibilantBounds = sibilantBoundsDistance;
        end

        if iterations2 == 3

            %disp('Check peak amplitudes.')

            % define interval centers in ms
            sibilants = [];
            loopRun = 0;
                
            for i = 1:2:length(sibilantBounds)
                loopRun = loopRun + 1;
                sibilants(loopRun) = sibilantBounds(i) + ((sibilantBounds(i+1)-sibilantBounds(i))/2);
            end

            amplitudes = [];
            % get sibilants' amplitudes
            for i = 1:length(sibilants)
                amplitudes(i) = rmsRatioSmooth(round(sibilants(i)*samplerate));
            end

            lowerThreshold = 0.8;
            upperThreshold = 1.2;

            % check which amplitudes are similar               
            iterations3 = 0;

            sibilantBoundsSimilarity = [];

            while length(sibilantBoundsSimilarity) ~= 4

                iterations3 = iterations3 + 1;

                %make comparison more conservative after initial iteration
                if iterations3 > 2 & length(sibilantBoundsSimilarity) > 4
                   lowerThreshold = lowerThreshold+0.1;
                   upperThreshold = upperThreshold-0.1;
                end

                if iterations3 > 2 & length(sibilantBoundsSimilarity) < 4
                    lowerThreshold = lowerThreshold-0.1;
                    upperThreshold = upperThreshold+0.1;
                end

                % loop through all amplitudes
                for i = 1:length(amplitudes)-1 %don't check the last amplitude

                    currentAmplitude = amplitudes(i);
                    lowerBound = currentAmplitude*lowerThreshold;
                    upperBound = currentAmplitude*upperThreshold;

                    % compare current amplitude to all remaining
                    for j = i+1:length(amplitudes)

                        if amplitudes(j) > lowerThreshold & amplitudes(j) < upperThreshold
                            sibilantBoundsSimilarity = [sibilantBoundsSimilarity sibilantBounds(i*2-1) sibilantBounds(i*2)];
                            sibilantBoundsSimilarity = [sibilantBoundsSimilarity sibilantBounds(j*2-1) sibilantBounds(j*2)];
                        end
                    end

                    sibilantBoundsSimilarity = unique(sibilantBoundsSimilarity);
                end

                % transform
                %sibilantBoundsSimilarity = sibilantBoundsSimilarity';

                if iterations3 == 50 
                    %disp('Abort peak check after 50 itereations.')
                    break
                end
            end

            % set check flag
            if length(sibilantBoundsSimilarity) ~= 4
                %disp('Peak similarity check failed.')
                similarityFlag = 0;
            else
                %disp('Peak similarity check successfull.')
            end

            if length(sibilantBoundsSimilarity) < 4
                method=0; % for peak finding
            end
            
            sibilantBounds = sibilantBoundsSimilarity;
        end

        if iterations2 > 3
            break
        end
    end

    if method

        %if at least two checks successfull: take bounds
        if durationFlag+distanceFlag > 1 | durationFlag+similarityFlag > 1 | distanceFlag+similarityFlag > 1
            if durationFlag+distanceFlag+similarityFlag > 2
                disp('All three checks successfull.')

                if isequal(sibilantBoundsDurations, sibilantBoundsDistance)
                    if isequal(sibilantBoundsDurations, sibilantBoundsSimilarity)
                        sibilantBounds = sibilantBoundsDurations;
                    end
                end
            else
                disp('Two checks successfull.')
            
                if isequal(sibilantBoundsDurations, sibilantBoundsDistance)
                        sibilantBounds = sibilantBoundsDurations;
                elseif isequal(sibilantBoundsDurations, sibilantBoundsSimilarity)
                        sibilantBounds = sibilantBoundsDurations;
                elseif isequal(sibilantBoundsDistance, sibilantBoundsSimilarity)
                    sibilantBounds = sibilantBoundsDistance;
                end
            end
        else
            disp('Less than two check successfull.')
            if similarityFlag
                method=0; %for peak finding
            elseif distanceFlag
                keyboard
                sibilantBounds = sibilantBoundsDistance;
            elseif durationFlag
                sibilantBounds = sibilantBoundsDurations;
            end
        end

        if durationFlag+distanceFlag+similarityFlag == 0
            disp('No check successfull.')
            method=0; %for peak finding
        end
    end

    % apply peaks finding when zero-crossing failed
    if ~method 
        
        disp('Try to find peaks instead.')

        % find peaks in RMSRatio (high frequency energy)
        [pksRatio, ratioStamps] = findpeaks(rmsRatio, timeFrame, 'MinPeakProminence', 0.03);


        if pertValid
        
            fricativeCenter1 = onsetOstF+fricativeDuration/2;
            fricative1Pk = rmsRatio(round(fricativeCenter1*500));
            smoothStamps = [];

        else
            
            % find the vowel nuclei for Lasse erhielt eine Tasse == 6-7
            % default distance between vowels assumed to be 95 ms
            [~, smoothStamps] = findpeaks(rmsCurveSmooth, timeFrame, 'MinPeakProminence', 0.02, 'MinPeakDistance', 0.3); %0.095
    
            %define vowels potentially flanking the first sibilant
            vowel1 = smoothStamps(1); %first vowel
            vowel2 = 0;
                
            if length(smoothStamps) > 1
                vowel2 = smoothStamps(2);
            end
            % vowel3 = smoothStamps(end-1);
            % vowel4 = smoothStamps(end); %last vowel 

            %fricativeCenter1Indx = min(find(ratioStamps > vowel1));

            % search for the high energy peak between vowels (only one is taken)
            fricativeCenter1Indx = min(find(ratioStamps > vowel1 & ratioStamps < vowel2));

            % % check if the index is missing -> take first peak after 2nd vowel
            if isempty(fricativeCenter1Indx)
                fricativeCenter1Indx = min(find(ratioStamps > vowel2));
            end

            % get time stamp of the sibilant peak
            fricativeCenter1 = ratioStamps(fricativeCenter1Indx);

            %check the level of the first sibilant peak
            fricative1Pk = pksRatio(fricativeCenter1Indx);
        end

        lowerThreshold = fricative1Pk*0.60; %85
        upperThreshold = fricative1Pk*1.4; %15

        % find peaks with approximately the same level as sibilant 1
        pksApproximate = find(pksRatio < upperThreshold & pksRatio > lowerThreshold);

        % select only peaks with approximately the same level as sibilant 1 
        ratioStampsReduced = ratioStamps(pksApproximate);

        % from these peaks select a peak that is at least 750 ms but not more
        % than 1.5 sec away from the first sibilant
        fricativeCenter2 = max(ratioStampsReduced(ratioStampsReduced > fricativeCenter1+0.075 & ratioStampsReduced < fricativeCenter1+1.7));

    end
    
    % get fricative bounds and center from zero-crossing
    if method     
        onsetF1 = sibilantBounds(1);
        offsetF1 = sibilantBounds(2);
        onsetF2 = sibilantBounds(3);
        offsetF2 = sibilantBounds(4);

        fricativeCenter1 = onsetF1+((offsetF1-onsetF1)/2);
        fricativeCenter2 = onsetF2+((offsetF2-onsetF2)/2);

        % define dummys for ploting
        smoothStamps = [];
        ratioStamps = [];
    else % define onsets and offsets from peaks finding
        
        onsetF1 = fricativeCenter1-0.02;
        offsetF1 = fricativeCenter1+0.02;
        onsetF2 = fricativeCenter2-0.02;
        offsetF2 = fricativeCenter2+0.02;    
    end

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
    parameterStruct.pertValid = pertValid;
    parameterStruct.timeFrame = timeFrame;
    parameterStruct.rmsCurveSmooth = rmsCurveSmooth;
    parameterStruct.rmsRatio = rmsRatio;
    parameterStruct.smoothStamps = smoothStamps;
    parameterStruct.ratioStamps = ratioStamps;
    parameterStruct.ostBoundaries = ostTimeStamps;
    parameterStruct.timeStampsFricatives = timeStampsFricatives;
    parameterStruct.fricativeCenterPerturbed = fricativeCenter1;
    parameterStruct.fricativeCenterNonPerturbed = fricativeCenter2;
    parameterStruct.method = method;
    
    % disp('Boundaries loaded in parameterStruct.')
    %keyboard

end

function [parameterStruct] = matchAudioKinematics(parameterStruct)
    
    signalFolder = parameterStruct.signalFolder;
    signalFile = parameterStruct.signalFile;
    fileNr = parameterStruct.fileNr;
    %audapterSamplerate = parameterStruct.samplerate;
    kinematicsFolder = parameterStruct.kinematicsFolder;

    emaAudioFolder = fullfile(kinematicsFolder, 'wav');
    
    % load the acoustic data from Audapter
    load(fullfile(signalFolder, signalFile), 'data', 'samplerate');

    signalAudapter = data(:,1);

    % load acoustic data from EMA
    [emaAudio, emaSamplerate] = audioread(fullfile(emaAudioFolder, [fileNr '.wav']));

    % resample ema audio to match Audapter's signal
    [P, Q] = rat(samplerate/emaSamplerate);
    signalEMA = resample(emaAudio, P, Q);

    % get the lag between the two signals
    [acor, lag] = xcorr(signalAudapter, signalEMA);
    [~, I] = max(abs(acor));
    lagDiff = lag(I);

    % convert lag to time delay in ms
    timeDiff = lagDiff/samplerate;

    % subtract timeDiff from time staps got from Audapter's audio
    % to get corresponding time stamps in ema audio
    parameterStruct.fricativeCenterPerturbedEMA = parameterStruct.fricativeCenterPerturbed - timeDiff;
    parameterStruct.fricativeCenterNonPerturbedEMA = parameterStruct.fricativeCenterNonPerturbed - timeDiff;
    parameterStruct.fileLength = length(emaAudio)/emaSamplerate;
    parameterStruct.emaAudioFolder = emaAudioFolder;

end

function writeTextGrid(parameterStruct, fileNr, familiarization)

    %default
    if ~isstruct(parameterStruct) & ~familiarization

        disp('Default TextGrid written.')
        %keyboard
        emaAudioFolder = fullfile(parameterStruct, 'wav');
        % load acoustic data from EMA
        [emaAudio, emaSamplerate] = audioread(fullfile(emaAudioFolder, [fileNr '.wav']));
        fileLength = length(emaAudio)/emaSamplerate;

        txtStruct{1} = ['File type = "ooTextFile"'];
        txtStruct{2} = ['Object class = "TextGrid"'];
        txtStruct{3} = ['xmin = 0'];
        txtStruct{4} = ['xmax = ' num2str(fileLength)];
        txtStruct{5} = ['tiers? <exists> '];
        txtStruct{6} = ['size = 2'];
        txtStruct{7} = ['item []:'];
        txtStruct{8} = ['item [1]:'];
        txtStruct{9} = ['class = "TextTier"'];
        txtStruct{10} = ['name = "token1"'];
        txtStruct{11} = ['xmin = 0'];
        txtStruct{12} = ['xmax = ' num2str(fileLength)];
        txtStruct{13} = ['points: size = 3'];
        txtStruct{14} = ['points [1]:'];
        txtStruct{15} = ['number = 1.5'];
        txtStruct{16} = ['mark = "onset"'];
        txtStruct{17} = ['points [2]:'];
        txtStruct{18} = ['number = 1.68'];
        txtStruct{19} = ['mark = "s_on" '];
        txtStruct{20} = ['points [3]:'];
        txtStruct{21} = ['number = 1.76'];
        txtStruct{22} = ['mark = "s_off"'];
        txtStruct{23} = ['item [2]:'];
        txtStruct{24} = ['class = "TextTier"'];
        txtStruct{25} = ['name = "token2"'];
        txtStruct{26} = ['xmin = 0'];
        txtStruct{27} = ['xmax = ' num2str(fileLength)];
        txtStruct{28} = ['points: size = 3'];
        txtStruct{29} = ['points [1]:'];
        txtStruct{30} = ['number = 2.77'];
        txtStruct{31} = ['mark = "onset"'];
        txtStruct{32} = ['points [2]:'];
        txtStruct{33} = ['number = 2.95'];
        txtStruct{34} = ['mark = "s_on" '];
        txtStruct{35} = ['points [3]:'];
        txtStruct{36} = ['number = 3.03'];
        txtStruct{37} = ['mark = "s_off"'];

    elseif ~isstruct(parameterStruct) & familiarization

        disp('Familiarization TextGrid written.')
        %keyboard
        emaAudioFolder = fullfile(parameterStruct, 'wav');
        % load acoustic data from EMA
        [emaAudio, emaSamplerate] = audioread(fullfile(emaAudioFolder, [fileNr '.wav']));
        fileLength = length(emaAudio)/emaSamplerate;

        txtStruct{1} = ['File type = "ooTextFile"'];
        txtStruct{2} = ['Object class = "TextGrid"'];
        txtStruct{3} = ['xmin = 0'];
        txtStruct{4} = ['xmax = ' num2str(fileLength)];
        txtStruct{5} = ['tiers? <exists> '];
        txtStruct{6} = ['size = 3'];
        txtStruct{7} = ['item []:'];
        txtStruct{8} = ['item [1]:'];
        txtStruct{9} = ['class = "TextTier" '];
        txtStruct{10} = ['name = "s" '];
        txtStruct{11} = ['xmin = 0 '];
        txtStruct{12} = ['xmax = ' num2str(fileLength)];
        txtStruct{13} = ['points: size = 8'];
        txtStruct{14} = ['points [1]:'];
        txtStruct{15} = ['number = 1.3776596534793466 '];
        txtStruct{16} = ['mark = "on" '];
        txtStruct{17} = ['points [2]:'];
        txtStruct{18} = ['number = 1.4695072424001399 '];
        txtStruct{19} = ['mark = "off" '];
        txtStruct{20} = ['points [3]:'];
        txtStruct{21} = ['number = 1.8726161048858438 '];
        txtStruct{22} = ['mark = "on" '];
        txtStruct{23} = ['points [4]:'];
        txtStruct{24} = ['number = 1.9644636938066373 '];
        txtStruct{25} = ['mark = "off" '];
        txtStruct{26} = ['points [5]:'];
        txtStruct{27} = ['number = 2.176223412707355 '];
        txtStruct{28} = ['mark = "on" '];
        txtStruct{29} = ['points [6]:'];
        txtStruct{30} = ['number = 2.2833789331149474 '];
        txtStruct{31} = ['mark = "off" '];
        txtStruct{32} = ['points [7]:'];
        txtStruct{33} = ['number = 2.586986240936459 '];
        txtStruct{34} = ['mark = "on" '];
        txtStruct{35} = ['points [8]:'];
        txtStruct{36} = ['number = 2.6609745764559865 '];
        txtStruct{37} = ['mark = "off" '];
        txtStruct{38} = ['item [2]:'];
        txtStruct{39} = ['class = "TextTier" '];
        txtStruct{40} = ['name = "S" '];
        txtStruct{41} = ['xmin = 0'];
        txtStruct{42} = ['xmax = ' num2str(fileLength)];
        txtStruct{43} = ['points: size = 0'];
        txtStruct{44} = ['item [3]:'];
        txtStruct{45} = ['class = "TextTier"'];
        txtStruct{46} = ['name = "z"'];
        txtStruct{47} = ['xmin = 0'];
        txtStruct{48} = ['xmax = ' num2str(fileLength)];
        txtStruct{49} = ['points: size = 0'];


    else
        
        disp('Experimental TextGrid written.')

        centerToken1 = parameterStruct.fricativeCenterPerturbedEMA;
        centerToken2 = parameterStruct.fricativeCenterNonPerturbedEMA;
        fileLength = parameterStruct.fileLength;
        emaAudioFolder = parameterStruct.emaAudioFolder;
        fileNr = parameterStruct.fileNr;

        %crude estimation
        onsetToken1 = centerToken1 - 0.17;
        onsetSToken1 = centerToken1 - 0.045;
        offsetSToken1 = centerToken1 + 0.045;

        onsetToken2 = centerToken2 - 0.17;
        onsetSToken2 = centerToken2 - 0.045;
        offsetSToken2 = centerToken2 + 0.045;

        txtStruct{1} = ['File type = "ooTextFile"'];
        txtStruct{2} = ['Object class = "TextGrid"'];
        txtStruct{3} = ['xmin = 0'];
        txtStruct{4} = ['xmax = ' num2str(fileLength)];
        txtStruct{5} = ['tiers? <exists> '];
        txtStruct{6} = ['size = 2'];
        txtStruct{7} = ['item []:'];
        txtStruct{8} = ['item [1]:'];
        txtStruct{9} = ['class = "TextTier"'];
        txtStruct{10} = ['name = "token1"'];
        txtStruct{11} = ['xmin = 0'];
        txtStruct{12} = ['xmax = ' num2str(fileLength)];
        txtStruct{13} = ['points: size = 3'];
        txtStruct{14} = ['points [1]:'];
        txtStruct{15} = ['number = ' num2str(onsetToken1)];
        txtStruct{16} = ['mark = "onset"'];
        txtStruct{17} = ['points [2]:'];
        txtStruct{18} = ['number = ' num2str(onsetSToken1)];
        txtStruct{19} = ['mark = "s_on" '];
        txtStruct{20} = ['points [3]:'];
        txtStruct{21} = ['number = ' num2str(offsetSToken1)];
        txtStruct{22} = ['mark = "s_off"'];
        txtStruct{23} = ['item [2]:'];
        txtStruct{24} = ['class = "TextTier"'];
        txtStruct{25} = ['name = "token2"'];
        txtStruct{26} = ['xmin = 0'];
        txtStruct{27} = ['xmax = ' num2str(fileLength)];
        txtStruct{28} = ['points: size = 3'];
        txtStruct{29} = ['points [1]:'];
        txtStruct{30} = ['number = ' num2str(onsetToken2)];
        txtStruct{31} = ['mark = "onset"'];
        txtStruct{32} = ['points [2]:'];
        txtStruct{33} = ['number = ' num2str(onsetSToken2)];
        txtStruct{34} = ['mark = "s_on" '];
        txtStruct{35} = ['points [3]:'];
        txtStruct{36} = ['number = ' num2str(offsetSToken2)];
        txtStruct{37} = ['mark = "s_off"'];
        %txtStruct{38} = [''];

    end

    %keyboard
    gridFile = fullfile(emaAudioFolder, [fileNr '.TextGrid']); 
    gridFileID = fopen(gridFile,'wt');

    for lines = 1:numel(txtStruct)
        fprintf(gridFileID, '%s\n', txtStruct{lines});
    end
    
    fclose(gridFileID);

end
