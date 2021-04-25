function saveSmomentsTable(subjectFolder, smoments)
% saves all data to an excel table for further statistical analyses,
% e.g. with R

% get subject's name from the subject path
i = 1;
while 1
    [str, subjectFolder] = strtok(subjectFolder, '\');
    if isempty(str),  break;  end
    pathInfo{i} = sprintf('%s', str);
    i = i + 1;
end

subject = pathInfo{4};

% save the experimental phase of the extracted smoments
phase = smoments.phase;

outputFile = fullfile(pathInfo{1}, pathInfo{2}, ['smoments_' subject '_' phase '.xlsx']);

% remove the phase field before looping through the struct
if isfield(smoments, 'phase')
    smoments = rmfield(smoments, 'phase');
end

% get field names
fields = fieldnames(smoments);

header = {'subject' 'phase' 'stimulus' 'trial' 'CoG' 'skewness' 'kurtosis'};

for snd = 1:length(fields)
    if snd == 1

        %keyboard
        % sndLables = horzcat(cellstr(repmat([subject '  '], length(eval(['smoments.' fields{snd}])), 1)), ...
        %             cellstr(repmat([phase '  '], length(eval(['smoments.' fields{snd}])), 1)), ...
        %             cellstr(repmat([strtok(fields{snd}, 'S') '  '], length(eval(['smoments.' fields{snd}])), 1)), ...
        %             num2cell(eval(['smoments.' fields{snd}])));

        sndLables = horzcat(cellstr(repmat([subject '  '], size(eval(['smoments.' fields{snd}]), 1), 1)), ...
                    cellstr(repmat([phase '  '], size(eval(['smoments.' fields{snd}]), 1), 1)), ...
                    cellstr(repmat([strtok(fields{snd}, 'S') '  '], size(eval(['smoments.' fields{snd}]), 1), 1)), ...
                    num2cell(eval(['smoments.' fields{snd}])));
        sndLables = vertcat(header, sndLables);

    else
        % sndLables = horzcat(cellstr(repmat([subject '  '], length(eval(['smoments.' fields{snd}])), 1)), ...
        %             cellstr(repmat([phase '  '], length(eval(['smoments.' fields{snd}])), 1)), ...
        %             cellstr(repmat([strtok(fields{snd}, 'S') '  '], length(eval(['smoments.' fields{snd}])), 1)), ...
        %             num2cell(eval(['smoments.' fields{snd}])));

        sndLables = horzcat(cellstr(repmat([subject '  '], size(eval(['smoments.' fields{snd}]), 1), 1)), ...
                    cellstr(repmat([phase '  '], size(eval(['smoments.' fields{snd}]), 1), 1)), ...
                    cellstr(repmat([strtok(fields{snd}, 'S') '  '], size(eval(['smoments.' fields{snd}]), 1), 1)), ...
                    num2cell(eval(['smoments.' fields{snd}])));
    end

    if ~exist('allLables', 'var')
        allLables = sndLables;
    else
        allLables = [allLables; sndLables];
    end
end

%keyboard

xlswrite(outputFile, allLables);

