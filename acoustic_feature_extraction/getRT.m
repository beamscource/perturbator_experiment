
function getRT(subjectFolder)
    content = dir(subjectFolder);
    folderList = content(find(vertcat(content.isdir)));

    for folder = 1:length(folderList)
   
        phase = folderList(folder).name;
    
        if strcmp(phase, '.') || strcmp(phase, '..') || strcmp(phase, 'soundcheck') || strcmp(phase, 'testing')
           	continue
        end
    
        RTs = extractRTData(subjectFolder, phase);
        
        try
            saveRTData(subjectFolder, RTs)
        catch
            warning('The RTs table seems to be empty.')
        end
    end
end


function RTs = extractRTData(subjectFolder, phase)
    
    phaseFolder = fullfile(subjectFolder, phase);
    analysis = 'analysis';
    analysisFolder = fullfile(phaseFolder, analysis);
    
    fileList = dir([analysisFolder '\*.mat']);
    
    % create an empty RTs struct
    RTs = {};
    
       for file = 1:length(fileList)
            
            rt = [];
            
            % set current file name and load the analysis data
            fileName = fileList(file).name;
            fileNameCopy = fileName;
            
            % get stimulus name from the file name:
            % sound name is always in the second position trialnumber_soundname_
            loop = 0;
            while 1
                [token, fileNameCopy] = strtok(fileNameCopy, '_');
                loop = loop + 1;
                if loop == 2, break; end
            end
            soundName{file} = token;
        
            load(fullfile(analysisFolder, fileName), 'data', 'descriptor');
            
            %convert the descriptor fields to cell array
            descriptor = cellstr(descriptor);
    
            rms = 'RMS_smoothed';
            time = 'frametime';
            
            rmsVector = data(:,find(strcmp(descriptor, rms)));
            timeScale = data(:,find(strcmp(descriptor, time)));
            
            % find sudden change in the vector
            jump = find(rmsVector > 0.02, 1, 'first');
            
%             plot(rmsVector)
%             hold on
%             
%             if ~isempty(jump)
%                 plot(jump, 0.1, 'o')
%             end
%             
%             pause(0.5)
            
            rt = timeScale(jump);
            
            % write the medians to a struct using dynamic expressions (sound names) as field names
            if ~isfield(RTs, [soundName{file} 'RTs'])
                RTs.(sprintf('%s', [soundName{file} 'RTs'])) = [repmat(file, size(rt, 1), 1) rt];
            else
                RTs.(sprintf('%s', [soundName{file} 'RTs'])) = ...
                    [RTs.(sprintf('%s', [soundName{file} 'RTs'])); [repmat(file, size(rt, 1), 1) rt]];
            end
            
            close all
       end
       RTs.phase = phase;
end


function saveRTData(subjectFolder, RTs)
    
    % get subject's name from the subject path
    i = 1;
    while 1
        [str, subjectFolder] = strtok(subjectFolder, '\');
        if isempty(str),  break;  end
        pathInfo{i} = sprintf('%s', str);
        i = i + 1;
    end
    
    subject = pathInfo{6};
    
    % save the experimental phase of the extracted means
    phase = RTs.phase;
    
    outputFile = fullfile(pathInfo{1}, pathInfo{2}, ['RTs_' subject '_' phase '.xlsx']);
    
    % remove the phase field before looping through the struct
    if isfield(RTs, 'phase')
        RTs = rmfield(RTs, 'phase');
    end
    
    % get field names
    fields = fieldnames(RTs);
    
    header = {'subject' 'phase' 'stimulus' 'trial' 'rt'};
    
    for snd = 1:length(fields)
        if snd == 1
            
            sndLables = horzcat(cellstr(repmat([subject '  '], length(eval(['RTs.' fields{snd}])), 1)), ...
                cellstr(repmat([phase '  '], length(eval(['RTs.' fields{snd}])), 1)), ...
                cellstr(repmat([strtok(fields{snd}, 'R') '  '], length(eval(['RTs.' fields{snd}])), 1)), ...
                num2cell(eval(['RTs.' fields{snd}])));
            sndLables = vertcat(header, sndLables);
            
        else
            sndLables = horzcat(cellstr(repmat([subject '  '], length(eval(['RTs.' fields{snd}])), 1)), ...
                cellstr(repmat([phase '  '], length(eval(['RTs.' fields{snd}])), 1)), ...
                cellstr(repmat([strtok(fields{snd}, 'R') '  '], length(eval(['RTs.' fields{snd}])), 1)), ...
                num2cell(eval(['RTs.' fields{snd}])));
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
