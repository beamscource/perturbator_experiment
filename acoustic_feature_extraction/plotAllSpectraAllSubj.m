
% main directory with the data
baseDir = 'E:\perturbator\data';

subjList = {'ds_a_fr', 'ds_a_zr', 'ds_a_mm', 'ds_a_aa'};
% subjList = {'ds_b_a', 'ds_b_d', 'ds_b_eb', 'ds_b_k'};

% loop throgh subjects specified in the subjList
for i = 1:length(subjList)

	subjectFolder = fullfile(baseDir, subjList{i});

	if i ~= 1
		close(f1, dy, gy)
	end
	
	[f1, dy, gy] = plotAllSpectra(subjectFolder);
end

close(f1, dy, gy)

% get all open average figures in a list of handles
figList = findall(0,'type','figure');

meansDy = figure('Name', 'Participants'' dy Means');
meansGy = figure('Name', 'Participants'' gy Means');

for i = 1:length(figList)

	currentFig = figList(i);

	red = findobj(currentFig,'color','r', 'type','line');
	black = findobj(currentFig,'color','k', 'type','line'); % to ignore the text wich is in black
	blue = findobj(currentFig,'color','b', 'type','line');
	green = findobj(currentFig,'color','g', 'type','line');
	mar = findobj(currentFig,'color','m', 'type','line');

	x = get(blue,'xData');

	yred = get(red,'yData');
	yblack = get(black,'yData');
	yblue = get(blue,'yData');
	ygreen = get(green,'yData');
	ymar = get(mar,'yData');

	if mod(i, 2)
		figure(meansGy)
		hold on
		plot(x, yred, 'r')
		plot(x, yblack, 'k')
		plot(x, yblue, 'b')
		plot(x, ygreen, 'g')
		plot(x, ymar, 'm')
	else
		figure(meansDy)
		hold on
		plot(x, yred, 'r')
		plot(x, yblack, 'k')
		plot(x, yblue, 'b')
		plot(x, ygreen, 'g')
		plot(x, ymar, 'm')
	end
end

dym = figure('Name', 'Collective dy Means');
hold on
gym = figure('Name', 'Collective gy Means');
hold on

red = findobj(meansDy,'color','r'); 
yData = get(red,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mdi = mean(M,3);
figure(dym)
% normalize y dimension by subtracting the first sample from all samples
plot(x, (mdi-mdi(1)), 'r', 'LineWidth', 3)

red = findobj(meansGy,'color','r'); 
yData = get(red,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mgu = mean(M,3);
figure(gym)
plot(x, (mgu - mgu(1)), 'r', 'LineWidth', 3)

% get the data from the dy plot
black = findobj(meansDy,'color','k'); 
yData = get(black,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mdyb = mean(M,3);
figure(dym)
plot(x, (mdyb - mdyb(1)), 'k', 'LineWidth', 3)

blue = findobj(meansDy,'color','b'); 
yData = get(blue,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mdy2 = mean(M,3);
figure(dym)
plot(x, (mdy2 - mdy2(1)), 'b', 'LineWidth', 3)

green = findobj(meansDy,'color','g'); 
yData = get(green,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mdy3 = mean(M,3);
figure(dym)
plot(x, (mdy3 - mdy3(1)), 'g', 'LineWidth', 3)

mar = findobj(meansDy,'color','m'); 
yData = get(mar,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mdy4 = mean(M,3);
figure(dym)
plot(x, (mdy4 - mdy4(1)), 'm', 'LineWidth', 3)

%get the data from the gy plot
black = findobj(meansGy,'color','k'); 
yData = get(black,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mgyb = mean(M,3);
figure(gym)
plot(x, (mgyb - mgyb(1)), 'k', 'LineWidth', 3)

blue = findobj(meansGy,'color','b'); 
yData = get(blue,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mgy2 = mean(M,3);
figure(gym)
plot(x, (mgy2 - mgy2(1)), 'b', 'LineWidth', 3)

green = findobj(meansGy,'color','g'); 
yData = get(green,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mgy3 = mean(M,3);
figure(gym)
plot(x, (mgy3 - mgy3(1)), 'g', 'LineWidth', 3)

mar = findobj(meansGy,'color','m'); 
yData = get(mar,'yData');
% catercinate into 3D matrix
M = cat(3, yData{:});
% get the mean along third dimension
mgy4 = mean(M,3);
figure(gym)
plot(x, (mgy4 - mgy4(1)), 'm', 'LineWidth', 3)

legend('gu','gy baseline','gy 220 Hz', 'gy 370 Hz', 'gy 520 Hz');

figure(dym)
legend('di','dy baseline','dy 220 Hz', 'dy 370 Hz', 'dy 520 Hz');

close(meansGy, meansDy)
clear all
