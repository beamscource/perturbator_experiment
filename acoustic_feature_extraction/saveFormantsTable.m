function saveFormantsTable(subjectFolder, means)
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

% save the experimental phase of the extracted means
phase = means.phase;

outputFile = fullfile(pathInfo{1}, pathInfo{2}, ['formants_' subject '_' phase '.xlsx']);

% remove the phase field before looping through the struct
if isfield(means, 'phase')
    means = rmfield(means, 'phase');
end

% get field names
fields = fieldnames(means);

header = {'subject' 'phase' 'stimulus' 'trial' 'index' 'vowel_dur' 'F1' 'F2' 'F3' 'F1_shift' 'F2_shift'};

for snd = 1:length(fields)
    if snd == 1

        sndLables = horzcat(cellstr(repmat([subject '  '], length(eval(['means.' fields{snd}])), 1)), ...
                    cellstr(repmat([phase '  '], length(eval(['means.' fields{snd}])), 1)), ...
                    cellstr(repmat([strtok(fields{snd}, 'M') '  '], length(eval(['means.' fields{snd}])), 1)), ...
                    num2cell(eval(['means.' fields{snd}])));
        sndLables = vertcat(header, sndLables);

    else
        sndLables = horzcat(cellstr(repmat([subject '  '], length(eval(['means.' fields{snd}])), 1)), ...
                    cellstr(repmat([phase '  '], length(eval(['means.' fields{snd}])), 1)), ...
                    cellstr(repmat([strtok(fields{snd}, 'M') '  '], length(eval(['means.' fields{snd}])), 1)), ...
                    num2cell(eval(['means.' fields{snd}])));
    end

    if ~exist('allLables', 'var')
        allLables = sndLables;
    else
        allLables = [allLables; sndLables];
    end
end

%keyboard

xlswrite(outputFile, allLables);

