function [means] = extractPhaseMeans(subjectFolder, phase, gCheck)
    % extracting formants form analysis files from the passed phase

    %gCheck = 0;

    phaseFolder = fullfile(subjectFolder, phase);
    signal = 'signal';
    signalFolder = fullfile(phaseFolder, signal);

    analysis = 'analysis';
    %analysis = 'reanalysis';
    analysisFolder = fullfile(phaseFolder, analysis);

    fileList = dir([analysisFolder '\*.mat']);
    formantList = {'F1', 'F2', 'F3', 'F1_shift', 'F2_shift'};

    % create an empty means struct
    means = {};

    % go through each file in the analysisFolder folder
    for file = 1:length(fileList)
        
        % create a clean variable for formants
        meanFormants = [];

        % set current file name and load the data
        fileName = fileList(file).name;
        fileNameCopy = fileName;

        load(fullfile (analysisFolder, fileName), 'data', 'descriptor');

        %convert the descriptor fields to cell array
        descriptor = cellstr(descriptor);

        %get right time axis for graphical check/labeling
        timeAxis = data(:,1);
            
        % get stimulus name from the file name:
        % sound name is always in the second position trialnumber_soundname_
        loop = 0;
        while 1
            [token, fileNameCopy] = strtok(fileNameCopy, '_');
            loop = loop + 1;
            if loop == 2, break; end
        end
        soundName{file} = token;
        
        %find indeces of the columns where the formant data is located
        for i = 1:length(formantList)
            indexFormant(i) = find(strcmp(descriptor, formantList{i}));
        end

        %extract formant data
        for formant = 1:length(indexFormant)
            
            %save formant vector to a variable
            rawVector = data(:, indexFormant(formant));

            % find the samples where NaN switches to data and other way around
            intervalBoundary = find(diff(isnan(rawVector)) ~= 0);
            if length(intervalBoundary) == 1
                if ~isnan(rawVector(end))
                    intervalBoundary(2) = length(rawVector);
                elseif ~isnan(rawVector(1))
                    intervalBoundary = 1, intervalBoundary;
                end
            elseif length(intervalBoundary) == 0
                continue
            end
                
            % define intervals based on the found bondaries
            intervals = 0;
            for i = 1:length(intervalBoundary) - 1
                intervals(i) = pdist2(intervalBoundary(i), intervalBoundary(i + 1));
            end

            intervalNumber = length(intervals);
            
            % set a copy for a exhaustive while loop search
            intervalsCopy = intervals;

            % define initial values for the while loop
            i = 1;
            formantVector = {};
            SDformantVector = 0;
            
            while intervalNumber ~= 0
                % find the longest interval
                longInterval = max(intervalsCopy);

                %first and last samples of the longest interval
                firstSample = intervalBoundary(find(intervals == longInterval));
                lastSample = intervalBoundary(find(intervals == longInterval) + 1);
                
                % if the longest interval is too short there is probably no clean vowel in the recording
                if abs(firstSample-lastSample) < 180
                    break
                end
                
                % cut the formant vector to the length of the produced sound
                if ~isnan(rawVector(firstSample+1:lastSample))
                    formantVector{i} = rawVector(firstSample + 1:lastSample);
                    
                    % save the SD of the vector
                    SDformantVector(i) = std(formantVector{i});
                    % remove the checked interval from the interval list
                    intervalsCopy = intervalsCopy(intervalsCopy ~= longInterval);
                    
                    intervalNumber = intervalNumber - 1;
                    i = i + 1;
                    
                else
                    intervalsCopy = intervalsCopy(intervalsCopy ~= longInterval);
                    %intervalBoundary = intervalBoundary((find(interval ~= longInterval)));
                    intervalNumber = intervalNumber - 1;
                end
            end
            
            % choose formantVector with the smallest SD
            if length(formantVector) > 0
                formantVector = formantVector{find(SDformantVector == min(SDformantVector))};
            else
                continue
            end
            
            % trimm the start and end of the formantVector
            % find max value in the formantVector
            % check to the left and right of the value (works only for F2)


            % devide the vector into 4 parts and chose a 50% range from it
            forthVector = round(length(formantVector)/4);
            
            % check minimal length of the forth of the vowel
            if forthVector < 60
                continue
            end
            
            if length(formantVector) < 3*forthVector
                continue
            end
            
            rangeVector = formantVector(forthVector:3*forthVector);

            %meanFormants{formant} = round(mean(rangeVector)); struct
            % take rather median than mean value
            meanFormants(formant) = round(median(rangeVector));

            % save F1 and F2 vectors for inspection when gCheck flag 1
            if gCheck

                [~, subIndex] = ismember(rangeVector, rawVector);
                rangeVectorZero = vertcat(zeros(size(rawVector(1:subIndex(1)-1))), rangeVector, ...
                                                zeros(size(rawVector(subIndex(end)+1:end))));

                if strcmp(formantList(formant), 'F1')
                    vectors.rawF1 = rawVector;
                    %vectors.rangeF1 = rangeVector;
                    vectors.rangeF1 = rangeVectorZero;
                elseif strcmp(formantList(formant), 'F2')
                    vectors.rawF2 = rawVector;
                    %vectors.rangeF2 = rangeVector;
                    vectors.rangeF2 = rangeVectorZero;
                elseif strcmp(formantList(formant), 'F3')
                    vectors.rawF3 = rawVector;
                    %vectors.rangeF3 = rangeVector;
                    vectors.rangeF3 = rangeVectorZero;
                elseif strcmp(formantList(formant), 'F1_shift')
                    vectors.rawF1Shift = rawVector;
                    %vectors.rangeF1Shift = rangeVector;
                    vectors.rangeF1Shift = rangeVectorZero;
                elseif strcmp(formantList(formant), 'F2_shift')
                    vectors.rawF2Shift = rawVector;
                    %vectors.rangeF2Shift = rangeVector;
                    vectors.rangeF2Shift = rangeVectorZero;
                end

                if length(fieldnames(vectors)) == 10
 
                    % send the range vectors to graphical check
                    %meanFormantsManual = graphicCheck(vectors, soundName{file});
                    % or label the vowel boundaries to extract vectors
                    meanFormantsManual = graphicLabeling(vectors, soundName{file}, phase, signalFolder, fileName, timeAxis);
                    clearvars('vectors')

                    % replace the automatically found means with manual means
                    if ~isempty(meanFormantsManual)
                        meanFormants = meanFormantsManual;
                    end
                end
            end
        end

        
        if isempty(meanFormants) || size(meanFormants, 2) ~= 6
            meanFormants = repmat(NaN, 1, 6);
        end
        
        % write the medians to a struct using dynamic expressions (sound names) as field names
        if ~isfield(means, [soundName{file} 'Means'])
            means.(sprintf('%s', [soundName{file} 'Means'])) = [repmat(file, size(meanFormants, 1), 1) (1:size(meanFormants, 1))' meanFormants];
        else
            means.(sprintf('%s', [soundName{file} 'Means'])) = ...
            [means.(sprintf('%s', [soundName{file} 'Means'])); [repmat(file, size(meanFormants, 1), 1) (1:size(meanFormants, 1))' meanFormants]];
        end
    
        % if file == 2
        %     break
        % end
        
    end

    means.phase = phase;
end
