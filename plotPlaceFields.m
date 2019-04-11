function plotPlaceFields(spiketimesAll,positionData,UnitList,tetrode)


for i = 1:size(positionData,2)
    for ii = 1:size(spiketimesAll)
        currentSpikes = spiketimesAll{i};
        for j = 1:size(currentSpikes,2)
            
            fm = FiringMap(positionData{i},currentSpikes{j});
       
        
        figure;PlotColorMap(fm.rate,fm.time);title(strcat(tetrode, 'Unit',num2str(UnitList(j)),'Lap',num2str(i)))
        end
        
    end
end
end
