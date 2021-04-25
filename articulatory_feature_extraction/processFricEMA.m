function processFricEMA(subjectFolder)

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

        [fricEMAData] = processPhaseFricEMA(subjectFolder, kinematicsFolder, phase, 1);
        %saveFricEMATable(subjectFolder, fricEMAData)

        %keyboard
    end
       
end

function [fricEMAData] = processPhaseFricEMA(subjectFolder, kinematicsFolder, phase, gCheck)
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

        disp(['Processing file ' fileNr '.'])

        parameterStruct = getBoundaries(signalFolder, fileName, phase, gCheck);

        if isempty(parameterStruct)
            continue
        end

        parameterStruct.subjectFolder = subjectFolder;

        % graphical check for the estimated boundaries 
        %[parameterStruct] = graphicBoundariesCheck(parameterStruct, gCheck);

        parameterStruct.kinematicsFolder = kinematicsFolder;

        %find the delay between Audapter audio and EMA audio
        parameterStruct = matchAudioKinematics(parameterStruct);

        % get spectral data from Audapter
        trialAcoustics = getTrialAcoustics(parameterStruct);
        %disp(['Acoustics for file ' fileNr ' extracted.'])
        
        % get kinematic data from EMA
        trialKinematics = getTrialKinematics(parameterStruct);

        %disp(['Kinematics for file ' fileNr ' extracted.'])

        % combine both modalities
        trialData = [trialAcoustics trialKinematics];
        
        % write the trial data to a struct using dynamic expressions (sound names) as field names
        valid = parameterStruct.pertValid;
        soundName = parameterStruct.soundName;
        % fileNr = parameterStruct.fileNr;
        
        % trialNr pertValid repetion 
        % a_CoG a_SD a_skew a_kurt a_lowMinAmp a_lowPeakFr a_lowPeakAmp a_midPeakFr a_midPeakAmp a_highPeakFr a_highPeakAmp a_diffMidLowMinAmp a_diffMidLowAmp
        % a_diffHighMidAmp a_diffHighLowAmp a_rmsLow a_rmsMid a_rmsHigh a_rmsMidHigh a_diffHighMidRMS a_diffHighLowRMS a_diffMidLowRMS a_diffMidHighLowRMS
        % k_TB_x k_TB_y k_TB_z k_TM_x k_TM_y k_TM_z k_TT_x k_TT_y k_TT_z k_JAW_x k_JAW_y k_JAW_z
        
        try
            if ~isfield(fricEMAData, [soundName 'Frication'])
                fricEMAData.(sprintf('%s', [soundName 'Frication'])) = [repmat(str2num(fileNr), size(trialData, 1), 1) repmat(valid, size(trialData, 1), 1) trialData];
            else
                fricEMAData.(sprintf('%s', [soundName 'Frication'])) = ...
                [fricEMAData.(sprintf('%s', [soundName 'Frication'])); [repmat(str2num(fileNr), size(trialData, 1), 1) repmat(valid, size(trialData, 1), 1) trialData]];
            end
        catch
            disp('Make data struct went wrong.')
            keyboard
        end
        
        %keyboard
    end

    fricEMAData.phase = phase;
end

function parameterStruct = getBoundaries(signalFolder, fileName, phase, gCheck)
    
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

    %         disp('Try to find peaks.')

        %         if length(sibilantBounds) ~= 4
    %            sibilantBounds = zeros(1,4);
    %         end

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
    
            %adjust peak finding settings
            % if length(smoothStamps) < 5
            % % decrease distance between vowels (fast speaker)
            %     [~, smoothStamps] = findpeaks(rmsCurveSmooth, timeFrame, 'MinPeakProminence', 0.02, 'MinPeakDistance', 0.15); %0.07
            % elseif length(smoothStamps) > 7
            %     % increase distance between vowels (slow speaker)
            %     [~, smoothStamps] = findpeaks(rmsCurveSmooth, timeFrame, 'MinPeakProminence', 0.02, 'MinPeakDistance', 0.3); %0.12
            % end
    
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

    % chose the minimal peak (making sure only one peak is selected)
    %fricativeCenter2Indx = max(pksApproximate(pksApproximate > fricativeCenter1Indx));
    
    %based on 3rd vowel
    %fricativeCenter2Indx = min(find(ratioStamps > vowel3));
    
    %fricativeCenter2 = ratioStamps(fricativeCenter2Indx);
    
    % check for pausible VCV sequence at the start
    % if (fricativeCenter1-vowel1 < 0.09 | fricativeCenter1-vowel1 > 0.15) & (vowel2-fricativeCenter1 < 0.19 | vowel2-fricativeCenter1 > 0.35)
    %     parameterStruct = [];
    %     return
    % end

    % fricativeCenter1Index = find(rmsRatio == max(pksRatio));
    % fricativeCenter2Index = find(rmsRatio == max(pksRatio(pksRatio~=max(pksRatio))));

    % exchange the two peaks if found in wrong order
    % if (fricativeCenter1Index > fricativeCenter2Index)
    %     new1 = fricativeCenter2Index;
    %     new2 = fricativeCenter1Index;
    %     fricativeCenter1Index = new1;
    %     fricativeCenter2Index = new2;
    % end

    % adjust litte with a magic number :)
    % fricativeCenter1Index = fricativeCenter1Index - 25;
    % fricativeCenter2Index = fricativeCenter2Index - 25;

    % protect against negative or too long indeces
    % if fricativeCenter1Index < 0 | fricativeCenter1Index > size(data, 1)
    %     fricativeCenter1Index = 1;
    %     disp('Center of 1st sibilant set to zero.')
    % end

    % if fricativeCenter2Index < 0 | fricativeCenter2Index > size(data, 1)
    %     fricativeCenter2Index = 1;
    %     disp('Center of 2nd sibilant set to zero.')
    % end

    % % define onsets and offsets for both sibilants
    % onsetIndxF1 = fricativeCenter1Index-15;
    % offsetIndxF1 = fricativeCenter1Index+15;
    % onsetIndxF2 = fricativeCenter2Index-15;
    % offsetIndxF2 = fricativeCenter2Index+15;

    % % protect against negative or too long indeces
    % if onsetIndxF1 < 0 | onsetIndxF1 > size(data, 1)
    %     onsetIndxF1 = 1;
    %     disp('Onset of 1st sibilant set to zero.')
    % end

    % if onsetIndxF2 < 0 | onsetIndxF2 > size(data, 1)
    %     onsetIndxF2 = 1;
    %     disp('Onset of 2nd sibilant set to zero.')
    % end

    % % protect against negative or too long indeces
    % if offsetIndxF1 < 0 | offsetIndxF1 > size(data, 1)
    %     offsetIndxF1 = 1;
    %     disp('Offset of 1st sibilant set to zero.')
    % end

    % if offsetIndxF2 < 0 | offsetIndxF2 > size(data, 1)
    %     offsetIndxF2 = 1;
    %     disp('Offset of 2nd sibilant set to zero.')
    % end

    % get corresponding time stamps
    % onsetF1 = fricativeCenter1-0.02;
    % offsetF1 = fricativeCenter1+0.02;
    % onsetF2 = fricativeCenter2-0.02;
    % offsetF2 = fricativeCenter2+0.02;

    % intervalF1 = [onsetF1 offsetF1];
    % intervalF2 = [onsetF2 offsetF2];

    % timeStampsFricatives.intervalF1 = intervalF1;
    % timeStampsFricatives.intervalF2 = intervalF2;

    % % get segments as time stamps in sec
    % fricativeCenter1 = data(fricativeCenter1Index, 1);
    % fricativeCenter2 = data(fricativeCenter2Index, 1);

    % % correct for peaks outer OST bounds for first [s]
    % if (onsetOstF-fricativeCenter1) > 0.02
    %     fricativeDuration = offsetOstF-onsetOstF;
    %     if fricativeDuration > 0.06
    %         fricativeCenter1 = offsetOstF-(fricativeDuration/2);
    %     else
    %         fricativeCenter1 = onsetOstF;
    %     end
    % end

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

function [parameterStruct] = graphicBoundariesCheck(parameterStruct, gCheck)

        subjectFolder = parameterStruct.subjectFolder;
        signalFolder = parameterStruct.signalFolder;
        signalFile = parameterStruct.signalFile;
        phase = parameterStruct.phase;
        fileNr = parameterStruct.fileNr;
        soundName = parameterStruct.soundName;
        timeFrame = parameterStruct.timeFrame;
        valid = parameterStruct.pertValid;
        onsetOstF = parameterStruct.ostBoundaries.onsetOstF;
        offsetOstF = parameterStruct.ostBoundaries.offsetOstF;
        timeStampsFricatives = parameterStruct.timeStampsFricatives;
        fricativeCenter1 = parameterStruct.fricativeCenterPerturbed;
        fricativeCenter2 = parameterStruct.fricativeCenterNonPerturbed;
        rmsCurveSmooth = parameterStruct.rmsCurveSmooth;
        rmsRatio = parameterStruct.rmsRatio;
        smoothStamps = parameterStruct.smoothStamps;
        ratioStamps = parameterStruct.ratioStamps;
        method = parameterStruct.method;

        if isempty(timeStampsFricatives.intervalF1)
            timeStampsFricatives.intervalF1(1) = 0;
            timeStampsFricatives.intervalF1(2) = 0;
            disp(['Missing acoustic on/offset in 1st sibilant in ' fileNr '.'])
        end

        if isempty(timeStampsFricatives.intervalF2)
            timeStampsFricatives.intervalF2(1) = 0;
            timeStampsFricatives.intervalF2(2) = 0;
            disp(['Missing acoustic on/offset of 2nd sibilant in ' fileNr '.'])
        end

        if isempty(fricativeCenter1)
            fricativeCenter1 = 0;
            disp(['Missing acoustic center for 1st sibilant in ' fileNr '.'])
        end

        if isempty(fricativeCenter2)
            fricativeCenter2 = 0;
            disp(['Missing acoustic center for 2nd sibilant in ' fileNr '.'])
        end

        if valid
            valid = 'VALID';
        else
            valid = 'FAILED';
        end

        if method
            method = 'CROSS';
        else
            method = 'PEAKS';
        end

        gCheck = 0; %turn ginput off

        % load the acoustic data 
        load(fullfile(signalFolder, signalFile), 'data', 'samplerate');

        signalVector = double(data(:,1));

        % disp('Plot OST now.')
        % keyboard
        purple =  [0.5 0.1 0.5];
        orange = [0.9100 0.4100 0.1700];
        crimson = [220/255 20/255 60/255];
        lightblue = [30/255 144/255 255/255];

        scalingFactor = 70000; % to visibly plot the RMSRatio curve

        %play sound
        %soundsc(signalVector(:), samplerate)

        f = figure('Name', ['Phase ' phase ' file ' fileNr], 'units', 'normalized', 'outerposition', ...
        [0 0 1 1], 'NumberTitle', 'off', 'Visible', 'off');
        
        subplot(2,1,1)
        % iptsetpref('ImshowBorder','tight');
        % title(['Response: [' soundName '] ' valid], 'FontSize', 30, 'Color', 'red')
        % hold on
        % plot(signalVector(1:end-10*5000), 'b'); %1:end-10*5000
        % set(gca, 'YTick', []);
        % set(gca, 'XTick', []);
        % axis tight;

        %subplot(2,1,2)
        iptsetpref('ImshowBorder','tight');
        spgrambw(signalVector(1:end-samplerate*1.2), samplerate, 'i', 400, [2000, 12000], 60);
        hold on
        title(['Response: [' soundName '] ' valid ' ' method], 'FontSize', 30, 'Color', 'red')

        % plot RMSRatio curve
        plot(timeFrame, rmsRatio*scalingFactor, 'Color', purple,'LineWidth', 1)
        plot(timeFrame, rmsCurveSmooth*scalingFactor, 'Color', orange,'LineWidth', 1)

        % y dimension of the plot
        yDimension = ylim;

        % plot fricative OST boundaries
        plot([onsetOstF onsetOstF], [yDimension(1) yDimension(2)], 'Color', 'black', 'linestyle', '--', 'LineWidth', 2);
        plot([offsetOstF offsetOstF], [yDimension(1) yDimension(2)], 'Color', 'black', 'linestyle', '--', 'LineWidth', 2);

        %plot vowel time stamps
        for i = 1:length(smoothStamps)
            plot([smoothStamps(i) smoothStamps(i)], [yDimension(1) yDimension(2)], 'Color', orange, 'linestyle', '--', 'LineWidth', 1.5)
        end

        % plot fricative time stamps
        plot([timeStampsFricatives.intervalF1(1) timeStampsFricatives.intervalF1(1)], [yDimension(1) yDimension(2)], 'Color', crimson, 'linestyle', '--', 'LineWidth', 1);
        plot([timeStampsFricatives.intervalF1(2) timeStampsFricatives.intervalF1(2)], [yDimension(1) yDimension(2)], 'Color', crimson, 'linestyle', '--', 'LineWidth', 1);
        plot([timeStampsFricatives.intervalF2(1) timeStampsFricatives.intervalF2(1)], [yDimension(1) yDimension(2)], 'Color', lightblue, 'linestyle', '--', 'LineWidth', 1);
        plot([timeStampsFricatives.intervalF2(2) timeStampsFricatives.intervalF2(2)], [yDimension(1) yDimension(2)], 'Color', lightblue, 'linestyle', '--', 'LineWidth', 1);
        
        plot([fricativeCenter1 fricativeCenter1], [yDimension(1) yDimension(2)], 'Color', crimson, 'LineWidth', 1.5)
        plot([fricativeCenter2 fricativeCenter2], [yDimension(1) yDimension(2)], 'Color', lightblue, 'LineWidth', 1.5)
        
        % disp('ib4 graphic check.')
        % keyboard

        if gCheck
            % input own fricative land marks
            [fricativeMarks] = ginput(2);
        
            if ~isempty(fricativeMarks)
                parameterStruct.fricativeCenterPerturbed = fricativeMarks(1);
                parameterStruct.fricativeCenterNonPerturbed = fricativeMarks(2);
            end
        end

        %save the trial figure
        try
            figurePath = fullfile(subjectFolder, 'figures', [fileNr '_' valid '_' method '.png']);
            saveas(f, figurePath)
            %disp(['Figure for trial ' fileNr ' saved to disk.'])
        catch
            disp(['Error saving figure for trial ' fileNr '.'])
        end

        parameterStruct.samplerate = samplerate;

        close all
end

function [parameterStruct] = matchAudioKinematics(parameterStruct)
    
    signalFolder = parameterStruct.signalFolder;
    signalFile = parameterStruct.signalFile;
    fileNr = parameterStruct.fileNr;
    audapterSamplerate = parameterStruct.samplerate;
    kinematicsFolder = parameterStruct.kinematicsFolder;

    emaAudioFolder = fullfile(kinematicsFolder, 'wav');
    
    % load the acoustic data from Audapter
    load(fullfile(signalFolder, signalFile), 'data');

    signalAudapter = data(:,1);

    % load acoustic data from EMA
    [emaAudio, emaSamplerate] = audioread(fullfile(emaAudioFolder, [fileNr '.wav']));

    % resample ema audio to match Audapter's signal
    [P, Q] = rat(audapterSamplerate/emaSamplerate);
    signalEMA = resample(emaAudio, P, Q);

    % get the lag between the two signals
    [acor, lag] = xcorr(signalAudapter, signalEMA);
    [~, I] = max(abs(acor));
    lagDiff = lag(I);

    % convert lag to time delay in ms
    timeDiff = lagDiff/audapterSamplerate;

    % subtract timeDiff from time staps got from Audapter's audio
    % to get corresponding time stamps in ema audio
    parameterStruct.fricativeCenterPerturbedEMA = parameterStruct.fricativeCenterPerturbed - timeDiff;
    parameterStruct.fricativeCenterNonPerturbedEMA = parameterStruct.fricativeCenterNonPerturbed - timeDiff;
    
    % disp('Delay between Audapter and EMA computed.')
    % keyboard
    % % check the delay visually
    % t1 = (0:length(signalAudapter)-1)/audapterSamplerate;
    % t2 = (0:length(signalEMA)-1)/audapterSamplerate;

    % subplot(2,1,1)
    % plot(t1,signalAudapter)
    % title('s_1')

    % subplot(2,1,2)
    % plot(t2,signalEMA)
    % title('s_2')
    % xlabel('Time (s)')

    % % realign the signals taking the lag into account
    % s1al = signalAudapter(lagDiff:end);
    % t1al = (0:length(s1al)-1)/audapterSamplerate;

    % subplot(2,1,1)
    % plot(t1al,s1al)
    % title('s_1, aligned')

    % subplot(2,1,2)
    % plot(t2,signalEMA)
    % title('s_2')
    % xlabel('Time (s)')

end

function trialAcoustics = getTrialAcoustics(parameterStruct)

    signalFolder = parameterStruct.signalFolder;
    signalFile = parameterStruct.signalFile;
    samplerate = parameterStruct.samplerate;
    timeStampsFricatives = parameterStruct.timeStampsFricatives;
    fricativeCenter1 = parameterStruct.fricativeCenterPerturbed;
    fricativeCenter2 = parameterStruct.fricativeCenterNonPerturbed;

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
        filtFricative1 = filtSignal(round(timeStampsFricatives.intervalF1(1)*samplerate):round(timeStampsFricatives.intervalF1(2)*samplerate));
        filtFricative1Shift = filtShift(round(timeStampsFricatives.intervalF1(1)*samplerate):round(timeStampsFricatives.intervalF1(2)*samplerate));
        filtFricative2 = filtSignal(round(timeStampsFricatives.intervalF2(1)*samplerate):round(timeStampsFricatives.intervalF2(2)*samplerate));
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

    % add leading column for [s] repetion (essentially perturbation condition)
    token1 = [repmat(1, size(token1, 1), 1) token1];
    token2 = [repmat(2, size(token2, 1), 1) token2];

    trialAcoustics = [token1; token2];

    % disp('Spectral data combined.')
    % keyboard

end

function [spectralData] = computeSpectrum(signal, samplerate)

    winLength = 256;
    
    % comput CoG
    [frames, ~, ~] = enframe(signal, hamming(winLength, 'periodic'), winLength/4, 'p');
    
    % signal is splitted into 75% overlapping Hamming windows of length winLength
    % power spectrum is computed for each window
    [~, f] = pwelch(signal, hamming(winLength, 'periodic'), winLength/4, [], samplerate);

    % signal is splitted into 75% overlapping Hamming windows of length winLength
    % power spectrum is computed for each window
    %[~, f] = pwelch(signal, [], [], [], samplerate);
    
    % disp('Power spectrum computed.')
    %keyboard
    %plot(f, 10*log10(density), 'k')

    % computing mean over middle frames resulting in sigle data point rather than performing
    % vector normalization of the frames to 100 data points and define fricative middle
    %later during data analysis
    try
        frames = mean(frames(round(size(frames, 1)/2)-3:round(size(frames, 1)/2)+3,:), 1);
    catch
        disp('Number of frames too low to compute mean.')
        frames = mean(frames(round(size(frames, 1)/2):round(size(frames, 1)/2),:), 1);
    end
    %frames = mean(frames, 1); %mean over all frames

    % define frequency regions (low, mid, mid-high, high) (cf. Koenig et al. 2013)
    boundaryIndx0 = find(f==625);
    boundaryIndx1 = find(f==5500); %3000
    boundaryIndx2 = find(f==11000); %7000
    %boundaryIndx3 = find(f==12000);
    
    % original CoG for all computed frames
    for frame = 1:size(frames, 1)
        [CoG(frame), SD(frame), skew(frame), kurt(frame)] = getcog(f, frames(frame,:));
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
    for frame = 1:size(frames, 1)
        currentFrame = frames(frame,:);
        [ampValue, peakFrInx] = max(10*log10(currentFrame(boundaryIndx0:boundaryIndx1-1)));
        lowPeakAmp(frame) = ampValue;
        lowPeakFr(frame) = f(peakFrInx+boundaryIndx0-1);
    end

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
        highPeakFr(frame) = f(peakFrInx+boundaryIndx2-1);
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
    diffHighLowAmp = highPeakAmp - lowPeakAmp;
    diffMidLowAmp = midPeakAmp - lowPeakAmp;

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
    for frame = 1:size(frames, 1)
        currentFrame = frames(frame,:);
        rmsMidHigh(frame) = 10*log10(rms(currentFrame(boundaryIndx1:end)));
    end

    diffHighMidRMS = rmsHigh-rmsMid;
    diffHighLowRMS = rmsHigh-rmsLow;
    diffMidLowRMS = rmsMid-rmsLow;
    diffMidHighLowRMS = rmsMidHigh-rmsLow;

    % combine all vectors into a matrix
    try
        spectralData = [CoG' SD' skew' kurt' lowMinAmp' lowPeakFr' lowPeakAmp' midPeakFr' midPeakAmp' highPeakFr' highPeakAmp' ...
        diffMidLowMinAmp' diffMidLowAmp' diffHighMidAmp' diffHighLowAmp' rmsLow' rmsMid' rmsHigh' rmsMidHigh' diffHighMidRMS' ...
        diffHighLowRMS' diffMidLowRMS' diffMidHighLowRMS'];
    catch
        disp('Spectral data combination went wrong');
        keyboard
    end

end

function trialKinematics = getTrialKinematics(parameterStruct)

    kinematicsFolder = parameterStruct.kinematicsFolder;
    fricativeCenter1 = parameterStruct.fricativeCenterPerturbedEMA;
    fricativeCenter2 = parameterStruct.fricativeCenterNonPerturbedEMA;
    fileNr = parameterStruct.fileNr;

    % subfolder with positional data
    positionsFolder = fullfile(kinematicsFolder, 'pos');
    
    % load position data: 3D matrix with samples*coordinate*sensor
    load(fullfile(positionsFolder, [fileNr '.mat']), 'data', 'samplerate');

    % convert time stamps into samples
    fricativeCenter1Indx = round(fricativeCenter1*samplerate);
    fricativeCenter2Indx = round(fricativeCenter2*samplerate);

    % 4 = TB, 5 = TM, 6 = TT, 8 = JAW
    sensorList = [4 5 6 8];
    % 1 = X (left-right), 2 = Y (anterior-posterior), 3 = Z (bottom-down)
    dimensionList = [1 2 3];

    token1 = [];
    token2 = [];
    loopRun = 0;

    for sensor = sensorList

    
        for dim = dimensionList
            % count number of times a parameter was extracted
            loopRun = loopRun+1;

            try
                token1(loopRun) = data(fricativeCenter1Indx,dim,sensor);
                token2(loopRun) = data(fricativeCenter2Indx,dim,sensor);
            catch
                disp(['Problem accessing articulatory data in file ' fileNr '.'])
                trialKinematics = NaN(2, 12);
                return
            end
        end
    end

    %combine both [s] repetitions
    trialKinematics = [token1; token2];

    %keyboard

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

    % extra for stefanie (baseline repeated)
    if strcmp(namePhase, 'baseline') & strcmp(numPhase, '5')
        phase = namePhase;
    else
        phase = [namePhase '_' numPhase];
    end

    outputFile = fullfile(pathInfo{1}, pathInfo{2}, 'data_tables', 'fricEMA', ['fricatives_fricEMA_' subject '_' phase '.xlsx']);

    % remove the phase field before looping through the struct
    if isfield(fricEMAData, 'phase')
        fricEMAData = rmfield(fricEMAData, 'phase');
    end

    % get field names
    fields = fieldnames(fricEMAData);

    header = {'subject' 'phase' 'stimulus' 'trial' 'valid' 'repetition' 'a_CoG' 'a_SD' 'a_skew' 'a_kurt' ...
    'a_lowMinAmp' 'a_lowPeakFr' 'a_lowPeakAmp' 'a_midPeakFr' 'a_midPeakAmp' 'a_highPeakFr' 'a_highPeakAmp' ...
    'a_diffMidLowMinAmp' 'a_diffMidLowAmp' 'a_diffHighMidAmp' 'a_diffHighLowAmp' 'a_rmsLow' 'a_rmsMid' 'a_rmsHigh' ...
    'a_rmsMidHigh' 'a_diffHighMidRMS' 'a_diffHighLowRMS' 'a_diffMidLowRMS' 'a_diffMidHighLowRMS' 'a_CoG_shift' ...
    'a_SD_shift' 'a_skew_shift' 'a_kurt_shift' 'a_lowMinAmp_shift' 'a_lowPeakFr_shift' 'a_lowPeakAmp_shift' ...
    'a_midPeakFr_shift' 'a_midPeakAmp_shift' 'a_highPeakFr_shift' 'a_highPeakAmp_shift' 'a_diffMidLowMinAmp_shift' ...
    'a_diffMidLowAmp_shift' 'a_diffHighMidAmp_shift' 'a_diffHighLowAmp_shift' 'a_rmsLow_shift' 'a_rmsMid_shift' ...
    'a_rmsHigh_shift' 'a_rmsMidHigh_shift' 'a_diffHighMidRMS_shift' 'a_diffHighLowRMS_shift' 'a_diffMidLowRMS_shift' ...
    'a_diffMidHighLowRMS_shift' 'k_TB_x' 'k_TB_y' 'k_TB_z' 'k_TM_x' 'k_TM_y' 'k_TM_z' 'k_TT_x' 'k_TT_y' ...
    'k_TT_z' 'k_JAW_x' 'k_JAW_y' 'k_JAW_z'};


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