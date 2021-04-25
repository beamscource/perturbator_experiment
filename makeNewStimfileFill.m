function makeNewStimfileFill(vp, subjectfolder, phasefolder, repetitions, nlpc, f0)
% generate randomized stimulus file from a base stim file (containing
% participant-specific pertubation settings)
% for training and tryout phases only
% July 2016

%male default is 17, female 15
% if strcmp(gender, 'm')
%     nlpc = 19;
%     f0 = 110;
% else
%     nlpc = 16;
%     f0 = 170;
% end

if ~exist('nlpc', 'var')
    nlpc = input('Number of LPC coefficients? (male 17-19, female 15-17) : ','s');
    nlpc = str2double(nlpc);
end

if ~exist('f0', 'var')
    f0 = input('Fundamental frequency? (male 110-150, female 200-250): ','s');
    f0 = str2double(f0);
end

% reading the stim base file
basefile = 'stimfile_base';
sbase=file2str(fullfile(subjectfolder, [basefile '.txt']));
vv=find(sbase(:,1)==' ');
sbase(vv,:)=[];
lenb=size(sbase,1);
nbase=(lenb-3)/2; % number of conditions (vowels) in the stim base file
ipos=2;     %skip number of lines to get to the next condition

%base stimulus file must use this as a place holder for insertion of repetition number
myplaceholder='_REP#';  

%determine number of digits to use for repetition number in code
nrepdig=length(int2str(max(repetitions)));

outfile = strrep(basefile,'base', vp);
% specify the output folder for each subject
outfile = fullfile(phasefolder, outfile); 
fid=fopen([outfile '.txt'],'w');

settingsdone = 0;
% participant's nLPC and f0 settings
settingstr = ['#nLPC ' int2str(nlpc) '#f0 ' int2str(f0)]; 

fwrite(fid,[deblank(sbase(1,:)) crlf],'uchar');
% write the instructions at the beginning of the stim file
fwrite(fid,[deblank(sbase(2,:)) crlf],'uchar');
fwrite(fid,[deblank(sbase(3,:)) crlf],'uchar');

halftime1 = '50% des Abschnitts vorbei.';
halftime2 = 'Aufgabenbeschreibung';
%sbase = sbase(4:end,:);
repIndex = 1;

lenexperiment = repetitions;

%loop as long not all repetitions written to the file 
while repetitions > 0

    % check the length of the base stime file
    if nbase/2 == 2
        conditionList = 1:nbase/2;
        % include the last conditions only in 50% of the time (filler)
        if mod(repIndex, 2) == 0 
            conditionList = 1:nbase;
        end
    else
        conditionList = 1:nbase;
    end

    %keyboard
    
    % message that half of the experiment is over
    % if repIndex == round(lenexperiment/2)+1
    %     fwrite(fid, [halftime1 crlf],'uchar');
    %     fwrite(fid, [halftime2 crlf],'uchar');
    % end

    % write every condition reandomized into a file
    while ~isempty(conditionList)

        % select randomly a condition
        ccondition =  conditionList(randi(numel(conditionList)));
        % collect two lines with stimulus and settings
        tmps1 = deblank(sbase(ipos*ccondition+2, :));
        tmps2 = deblank(sbase(ipos*ccondition+3, :)); %settings

        % include the repetition number into settings
        tmps2x=strrep(tmps2, myplaceholder, ['_' int2str0(repIndex, nrepdig) '#']); 
        
        fwrite(fid,[tmps1 crlf],'uchar'); % write first line to the file

        % add formant tracking settings to the audapter settings for the first
        % stimulus
        if ~settingsdone
            ipi=findstr('%',tmps2x);
            tmps2x=[tmps2x(1:(ipi-1)) settingstr tmps2x(ipi:end)];
            settingsdone = 1;
        end
        fwrite(fid,[tmps2x crlf],'uchar'); % write second line to the file
        % delete that element from the list of conditions
        conditionList = conditionList(conditionList~=ccondition); 
        %keyboard
    end

    repIndex = repIndex + 1;
    repetitions = repetitions - 1;

end

% write close trial at the end of the stimulus file
fwrite(fid, ['Der Abschnitt ist zu Ende.' crlf],'uchar');
fwrite(fid, ['ENDE' crlf] ,'uchar');

fclose(fid);
