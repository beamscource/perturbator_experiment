function plotAvgSpectra(f1, dy, gy, subject)

	blue = findobj(dy,'color','b');
	xData = get(blue,'xData');
	x = xData{:,1}; 

	dym = figure('Name', [subject ': dy Means']);
	hold on
	gym = figure('Name', [subject ': gy Means']);
	hold on

	% get the data from the f1 plot
	red = findobj(dy,'color','r'); 
	yData = get(red,'yData');
	% catercinate into 3D matrix
	M = cat(3, yData{:});
	% get the mean along third dimension
	mdi = mean(M,3);
	figure(dym)
	% normalize y dimension by subtracting the first sample from all samples
	plot(x, (mdi-mdi(1)), 'r', 'LineWidth', 3)

	red = findobj(gy,'color','r'); 
	yData = get(red,'yData');
	% catercinate into 3D matrix
	M = cat(3, yData{:});
	% get the mean along third dimension
	mgu = mean(M,3);
	figure(gym)
	plot(x, (mgu - mgu(1)), 'r', 'LineWidth', 3)

	% get the data from the dy plot
	black = findobj(dy,'color','k'); 
	yData = get(black,'yData');
	% catercinate into 3D matrix
	M = cat(3, yData{:});
	% get the mean along third dimension
	mdyb = mean(M,3);
	figure(dym)
	plot(x, (mdyb - mdyb(1)), 'k', 'LineWidth', 3)

	blue = findobj(dy,'color','b'); 
	yData = get(blue,'yData');
	% catercinate into 3D matrix
	M = cat(3, yData{:});
	% get the mean along third dimension
	mdy2 = mean(M,3);
	figure(dym)
	plot(x, (mdy2 - mdy2(1)), 'b', 'LineWidth', 3)

	green = findobj(dy,'color','g'); 
	yData = get(green,'yData');
	% catercinate into 3D matrix
	M = cat(3, yData{:});
	% get the mean along third dimension
	mdy3 = mean(M,3);
	figure(dym)
	plot(x, (mdy3 - mdy3(1)), 'g', 'LineWidth', 3)

	mar = findobj(dy,'color','m'); 
	yData = get(mar,'yData');
	% catercinate into 3D matrix
	M = cat(3, yData{:});
	% get the mean along third dimension
	mdy4 = mean(M,3);
	figure(dym)
	plot(x, (mdy4 - mdy4(1)), 'm', 'LineWidth', 3)

	%get the data from the gy plot
	black = findobj(gy,'color','k'); 
	yData = get(black,'yData');
	% catercinate into 3D matrix
	M = cat(3, yData{:});
	% get the mean along third dimension
	mgyb = mean(M,3);
	figure(gym)
	plot(x, (mgyb - mgyb(1)), 'k', 'LineWidth', 3)

	blue = findobj(gy,'color','b'); 
	yData = get(blue,'yData');
	% catercinate into 3D matrix
	M = cat(3, yData{:});
	% get the mean along third dimension
	mgy2 = mean(M,3);
	figure(gym)
	plot(x, (mgy2 - mgy2(1)), 'b', 'LineWidth', 3)

	green = findobj(gy,'color','g'); 
	yData = get(green,'yData');
	% catercinate into 3D matrix
	M = cat(3, yData{:});
	% get the mean along third dimension
	mgy3 = mean(M,3);
	figure(gym)
	plot(x, (mgy3 - mgy3(1)), 'g', 'LineWidth', 3)

	mar = findobj(gy,'color','m'); 
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
end
%mean([yData{1,:}; yData{2,:}; yData{3,:}; yData{4,:}; yData{5,:}; yData{6,:}; ])
