function sensorCheckEMA(chanList, triaList, excludeList, matFolder, filtFolder) 
	
	tanflag = 0; % 0 == position data is displayed 1 == tang. vel.
	maxminflag = 0;	% 0 == SD 1 == max-min
	doshowtrial = 0;
	autoflag = 2; % 0 == pause after each trial 1 == pause after each sensor 2 == no pauses
	compsensor = 3; % preferably nose, but use most stable sensor
	diaryfileComp = ['comppos_stats_rawpos_comp_' int2str(compsensor) '.txt'];
		
	%exlude blank trials
	editList = setdiff(triaList, excludeList);
	%keyboard

	%compare each sensor with compsensor (nose sensor)
	do_comppos_a_f(matFolder, [], editList, chanList, compsensor, autoflag, diaryfileComp);

	% disp('Comparison with nose is done.')
	% keyboard
	% diaryfileFilt = ['comppos_stats_rawpos_filter.txt'];
	% %compare filtered and unfiltered data
	% do_comppos_a_f(matFolder, filtFolder, editList, chanList, [], autoflag, diaryfileFilt);
end