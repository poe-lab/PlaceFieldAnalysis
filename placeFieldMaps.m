function placeFieldMaps(UnitArray,lapTimestamps,position,UnitList,tetrode)

[spiketimesSet1, spiketimesSet2, spiketimesSet3] = TimestampSplitting(UnitArray,lapTimestamps);

spiketimesAll = {spiketimesSet1,spiketimesSet2,spiketimesSet3};

plotPlaceFields(spiketimesAll,position,UnitList,tetrode)

end
