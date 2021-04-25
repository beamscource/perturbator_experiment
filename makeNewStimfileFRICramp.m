function makeNewStimfileFRICramp(subjectID, subjectFolder, txtAStruct, repetitionsA, txtBStruct, repetitionsB, nLPC, f0, language)
    % generate randomized stimulus file from a text struct (containing
    % participant-specific tracking settings)


    if ~exist('language', 'var')
        language = input('Participant''s language (r/g): ','s');
    end


    lengthAStruct = length(txtAStruct);
    % number of stimuli in the stim base file
    numAStim = (lengthAStruct-3)/2;
    %number of lines to skip to get to the next stimulus
    skipLines = 2;     

    %a place holder for insertion of repetition number
    repPlaceholder = '_REP#';  
    %determine number of digits to use for repetition number in code
    numRepDig = length(int2str(max(repetitionsA)));

    [~, phase] = strtok(txtAStruct{3}, ' ');
    phase = strtrim(phase);
    stimFile = fullfile(subjectFolder, [phase '_' subjectID '.txt']); 
    stimFileID = fopen(stimFile,'wt');


    % participant's nLPC and f0 settings
    nLPCset = ['#nLPC ' int2str(nLPC) '#f0 ' int2str(f0)]; 


    % write the header of the file
    fprintf(stimFileID, '%s\n', txtAStruct{1});
    fprintf(stimFileID, '%s\n', txtAStruct{2});
    fprintf(stimFileID, '%s\n', txtAStruct{3});

    settingsdone = 0;
    repIndex = 0;

    %loop as long not all repetitions written to the file 
    while repetitionsA > 0    

        conditionList = 1:numAStim;

        % write every condition reandomized into a file
        while ~isempty(conditionList)

            % select randomly a condition
            randomCondition =  conditionList(randi(numel(conditionList)));
            % collect two lines with stimulus and settings
            tmps1 = txtAStruct{skipLines*randomCondition+2};
            tmps2 = txtAStruct{skipLines*randomCondition+3}; %settings

            % include the repetition number into settings
            tmps2x = strrep(tmps2, repPlaceholder, ['_' int2str0(repIndex, numRepDig) '#']); 

            fprintf(stimFileID, '%s\n', tmps1); % write first line to the file

            % add formant tracking settings to the audapter settings for the first
            % stimulus
            if ~settingsdone
                ipi = findstr('%',tmps2x);
                tmps2x = [tmps2x(1:(ipi-1)) nLPCset tmps2x(ipi:end)];
                settingsdone = 1;
            end
            
            % mark ramp trials in the stimulus name 
            if repIndex < 5
                [stimulus, tmps2x] = strtok(tmps2x, '_');
                switch repIndex
                    case 0
                        stimulus = [stimulus '1'];
                    case 1
                        stimulus = [stimulus '2'];
                    case 2
                        stimulus = [stimulus '3'];
                    case 3  
                        stimulus = [stimulus '4'];
                    case 4
                        stimulus = [stimulus '5'];
                end
                tmps2x = [stimulus tmps2x];
            end

            fprintf(stimFileID, '%s\n', tmps2x); % write second line to the file
                        
            % delete that element from the list of conditions
            conditionList = conditionList(conditionList~=randomCondition); 
            %keyboard
        end

        repIndex = repIndex + 1;
        repetitionsA = repetitionsA - 1;

    end

    %% second struct

    lengthBStruct = length(txtBStruct);
    % number of stimuli in the stim base file
    numBStim = (lengthBStruct-2)/2;
    %number of lines to skip to get to the next stimulus
    skipLines = 2;     

    %a place holder for insertion of repetition number
    repPlaceholder = '_REP#';  
    %determine number of digits to use for repetition number in code
    numRepDig = length(int2str(max(repetitionsB))); 

    % write the header of the file
    fprintf(stimFileID, '%s\n', txtBStruct{1});
    fprintf(stimFileID, '%s\n', txtBStruct{2});

    repIndex = 0;

    %loop as long not all repetitions written to the file 
    while repetitionsB > 0
        
        conditionList = 1:numBStim;

        % write every condition reandomized into a file
        while ~isempty(conditionList)

            % select randomly a condition
            randomCondition =  conditionList(randi(numel(conditionList)));
            % collect two lines with stimulus and settings
            tmps1 = txtBStruct{skipLines*randomCondition+1};
            tmps2 = txtBStruct{skipLines*randomCondition+2}; %settings

            % include the repetition number into settings
            tmps2x = strrep(tmps2, repPlaceholder, ['_' int2str0(repIndex, numRepDig) '#']); 

            fprintf(stimFileID, '%s\n', tmps1); % write first line to the file

            % add formant tracking settings to the audapter settings for the first
            % stimulus
            if ~settingsdone
                ipi = findstr('%',tmps2x);
                tmps2x = [tmps2x(1:(ipi-1)) nLPCset tmps2x(ipi:end)];
                settingsdone = 1;
            end
            
            fprintf(stimFileID, '%s\n', tmps2x); % write second line to the file
                        
            % delete that element from the list of conditions
            conditionList = conditionList(conditionList~=randomCondition); 
            %keyboard
        end

        repIndex = repIndex + 1;
        repetitionsB = repetitionsB - 1;

    end

    % write close trial at the end of the stimulus file
    if strcmp(language, 'r')
        fprintf(stimFileID, '%s\n', 'Сегмент закончен.');
    elseif strcmp(language, 'g')
        fprintf(stimFileID, '%s\n', 'Der Abschnitt ist zu Ende.');
    end
    
    fprintf(stimFileID, '%s', 'ENDE');
    fclose(stimFileID);
end