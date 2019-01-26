% Script to construct DOC box model: to calculate 'processing
% term' for each time period/box and explore DOC export from sta 160
% Includes 'adaptive' modeling to account for changes in the 'beginning' of
% the estuary
% A.G. Hounshell (ahounshell10@gmail.com), 28 Dec 2018

%% Load in data
% Load in data from salinity box model: ForOCBoxModel.mat
% Add total volume data for each station (in m^3)
% Determine in ArcGIS using the Estuarine Shoreline Mapping Project data
Vol.Tot = [5947595; 18017248; 29805909; 39391374; 80377844; 138295695; 139773655; 172935830; 330397257];
% Add variability (10%)
for j = 2:1002
    for i = 1:9
        a = Vol.Tot(i,1) - (Vol.Tot(i,1)*0.1);
        b = Vol.Tot(i,1) + (Vol.Tot(i,1)*0.1);
        Vol.Tot(i,j) = (b-a).*rand(1,1) + a;
    end
end
% Load in DOC data
[data.data, data.parms, data.raw] = xlsread ('OCData_Calc.xlsx');
% Convert to matlab datenum
data.time = datenum(data.raw(2:771), 'mm/dd/yyyy');
time = data.time(23:22:770);
% Separate into data from sta 20-180: data starts from 7-6-2015
icount = 1;
for i = 3:22:770
    doc.data (icount:icount+19,1) = data.data(i:i+19,1);
    doc.data (icount:icount+19,2) = data.data(i:i+19,3);
    doc.data (icount:icount+19,3) = data.data(i:i+19,6);
    icount = icount + 20;
end
% Separate data from sta 0: data from 7-20-15
icount = 1;
for i = 23:22:770
    zero.data (icount:icount+1,1) = data.data(i:i+1,3);
    zero.data (icount:icount+1,2) = data.data(i:i+1,6);
    icount = icount + 2;
end
% Add variability among Statio 0 data: 3.33% for DOC data
for j = 3:1003
    for i = 1:68
        a = zero.data(i,2) - (zero.data(i,2)*0.0333);
        b = zero.data(i,2) + (zero.data(i,2)*0.0333);
        zero.data(i,j) = (b-a).*rand(1,1) + a;
    end
end

% Average surface and bottom concentrations for station zero
% Represents the 'riverine end member'
for j = 2:1003
    icount = 0;
    for i = 1:2:68
        icount = icount + 1;
        zero.Avg (icount,j-1) = nanmean(zero.data(i:i+1,j));
    end
end

% Add variabilty to the rest of DOC data: 3.33% variability
for j = 4:1004
    for i = 1:700
        a = doc.data(i,3) - (doc.data(i,3)*0.0333);
        b = doc.data(i,3) + (doc.data(i,3)*0.0333);
        doc.data(i,j) = (b-a).*rand(1,1) + a;
    end
end
% Average S and B for each station: for time periods when the estuary is still acting as
% a river
for j = 3:1004
    icount = 0;
    for i = 1:2:700
        icount = icount + 1;
        doc.avg(icount,1) = doc.data(i,1);
        doc.avg(icount,2) = 3;
        doc.avg(icount,j) = nanmean(doc.data(i:i+1,j));
    end
end

%% Separate DOC by date
jcount = 0;
for j = 3:1004
    jcount = 1 + jcount;
    icount = 0;
    for i = 21:20:700
        icount = icount + 1;
        D{jcount,icount} (:,1) = doc.data(i:i+19,1);
        D{jcount,icount} (:,2) = doc.data(i:i+19,2);
        D{jcount,icount} (:,3) = doc.data(i:i+19,j);
    end
end
% Separate DOC average by date
jcount = 0;
for j = 3:1004
    jcount = 1 + jcount;
    icount = 0;
    for i = 11:10:350
        icount = icount + 1;
        DAvg{jcount,icount} (:,1) = doc.avg(i:i+9,1);
        DAvg{jcount,icount} (:,2) = doc.avg(i:i+9,2);
        DAvg{jcount,icount} (:,3) = doc.avg(i:i+9,j);
    end
end

%% Also need to calculate the change in DOC for each box
icount = 1;
for i = 1:22:770
    doc.time (icount:icount+19,1) = data.time(i:i+19,1);
    icount = icount + 20;
end
for j = 3:1004
    icount = 0;
    for i = 21:700
        icount = icount + 1;
        doc.DelCalc (icount,j-2) = (doc.data(i,j)-doc.data(i-20,j))/((doc.time(i,1)-doc.time(i-20,1))*24*60*60);
    end
end
% Then separate by date
jcount = 0;
for j = 1:1002
    jcount = 1 + jcount;
    icount = 0;
    for i = 1:20:680
        icount = icount + 1;
        DelDOC{jcount,icount} (:,1) = doc.data(i:i+19,1);
        DelDOC{jcount,icount} (:,2) = doc.data(i:i+19,2);
        DelDOC{jcount,icount} (:,3) = doc.DelCalc(i:i+19,j);
    end
end
% And calculate average change in DOC for each box (for when the estuary is acting like a river):
icount = 1;
for i = 1:22:770
    doc.time2 (icount:icount+9,1) = data.time(i:2:i+19,1);
    icount = icount + 10;
end
for j = 3:1004
    icount = 0;
    for i = 11:350
        icount = icount + 1;
        doc.DelCalcAvg (icount,j-2) = (doc.avg(i,j)-doc.avg(i-10,j))/((doc.time2(i,1)-doc.time2(i-10,1))*24*60*60);
    end
end
% Then separate by date
jcount = 0;
for j = 1:1002
    jcount = 1 + jcount;
    icount = 0;
    for i = 1:10:340
        icount = icount + 1;
        DelDOCAvg{jcount,icount} (:,1) = doc.avg(i:i+9,1);
        DelDOCAvg{jcount,icount} (:,2) = doc.avg(i:i+9,2);
        DelDOCAvg{jcount,icount} (:,3) = doc.DelCalcAvg(i:i+9,j);
    end
end

%% Then add a source/sink term to the DOC box model: pDOC
% Need to change the location of where the estuary 'starts': can still
% calculate a source/sink term for 'river' boxes using the DOC
% concentration into and out of the box
% 20: i = [3 4 5 6 8]
% Transition box: moving from river to estuary: pDOC surface and pDOC bottom
for j = 1:1002
    for k = [3 4 5 6 8]
        pDOC{j,k}(1,1) = ((Vol.Sur{j}(1,k)*DelDOC{j,k}(1,3))-(R(k,j)*zero.Avg(k,j))-(Q{j,k}(1,3)*D{j,k}(2,3))-(Q{j,k}(1,4)*(D{j,k}(2,3)-D{j,k}(1,3)))+((Q{j,k}(1,1)+PBoxes(1,k)-EBoxes(1,k))*D{j,k}(1,3)))*60*60*24/1000;
        pDOC{j,k}(1,2) = ((Vol.Bot{j}(1,k)*DelDOC{j,k}(2,3))-(Q{j,k}(1,2)*D{j,k}(4,3))+(Q{j,k}(1,3)*D{j,k}(2,3))+(Q{j,k}(1,4)*(D{j,k}(2,3)-D{j,k}(1,3))))*60*60*24/1000;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [3 4 5 6 8]
        icount = 1;
        for i = 3:2:17
            icount = icount + 1;
            pDOC{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*DelDOC{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*DelDOC{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24/1000;
        end
    end
end
% 30: k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
% River box: single layer flow, station 20
for j = 1:1002
    for k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
        for i = 1
            pDOC{j,k}(i,1) = ((DelDOCAvg{j,k}(i,3)*Vol.Tot(i,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(i,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary: pDOC surface and pDOC
% bottom, station 30
for j = 1:1002
    for k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
        pDOC{j,k}(2,1) = ((Vol.Sur{j}(2,k)*DelDOC{j,k}(3,3))-((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3))-(Q{j,k}(2,3)*D{j,k}(4,3))-(Q{j,k}(2,4)*(D{j,k}(4,3)-D{j,k}(3,3)))+((Q{j,k}(2,1)+PBoxes(2,k)-EBoxes(2,k))*D{j,k}(3,3)))*60*60*24/1000;
        pDOC{j,k}(2,2) = ((Vol.Bot{j}(2,k)*DelDOC{j,k}(4,3))-(Q{j,k}(2,2)*D{j,k}(6,3))+(Q{j,k}(2,3)*D{j,k}(4,3))+(Q{j,k}(2,4)*(D{j,k}(4,3)-D{j,k}(3,3))))*60*60*24/1000;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
        icount = 2;
        for i = 5:2:17
            icount = icount + 1;
            pDOC{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*DelDOC{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*DelDOC{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24/1000;
        end
    end
end
% 50: i = [9 14 17 27 30 32]
% River box: single layer flow
for j = 1:1002
    for k = [9 14 17 27 30 32]
        for i = 2
            pDOC{j,k}(1,1) = ((DelDOCAvg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24/1000;
            pDOC{j,k}(2,1) = ((DelDOCAvg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(2,k)-EBoxes(2,k))*DAvg{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(1:2,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary: pDOC surface and pDOC bottom
for j = 1:1002
    for k = [9 14 17 27 30 32]
        pDOC{j,k}(3,1) = ((Vol.Sur{j}(3,k)*DelDOC{j,k}(5,3))-((R(k,j)+sum(PBoxes(1:2,k))-sum(EBoxes(1:2,k)))*DAvg{j,k}(2,3))-(Q{j,k}(3,3)*D{j,k}(6,3))-(Q{j,k}(3,4)*(D{j,k}(6,3)-D{j,k}(5,3)))+((Q{j,k}(3,1)+PBoxes(3,k)-EBoxes(3,k))*D{j,k}(5,3)))*60*60*24/1000;
        pDOC{j,k}(3,2) = ((Vol.Bot{j}(3,k)*DelDOC{j,k}(6,3))-(Q{j,k}(3,2)*D{j,k}(8,3))+(Q{j,k}(3,3)*D{j,k}(6,3))+(Q{j,k}(3,4)*(D{j,k}(6,3)-D{j,k}(5,3))))*60*60*24/1000;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [9 14 17 27 30 32]
        icount = 3;
        for i = 7:2:17
            icount = icount + 1;
            pDOC{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*DelDOC{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*DelDOC{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24/1000;
        end
    end
end
% 60: i = [11 16 19]
% River box: single layer flow
for j = 1:1002
    for k = [11 16 19]
        for i = 2:3
            pDOC{j,k}(1,1) = ((DelDOCAvg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24/1000;
            pDOC{j,k}(i,1) = ((DelDOCAvg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(1:3,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary: pDOC surface and pDOC bottom
for j = 1:1002
    for k = [11 16 19]
        pDOC{j,k}(4,1) = ((Vol.Sur{j}(4,k)*DelDOC{j,k}(7,3))-((R(k,j)+sum(PBoxes(1:3,k))-sum(EBoxes(1:3,k)))*DAvg{j,k}(3,3))-(Q{j,k}(4,3)*D{j,k}(8,3))-(Q{j,k}(4,4)*(D{j,k}(8,3)-D{j,k}(7,3)))+((Q{j,k}(4,1)+PBoxes(4,k)-EBoxes(4,k))*D{j,k}(7,3)))*60*60*24/1000;
        pDOC{j,k}(4,2) = ((Vol.Bot{j}(4,k)*DelDOC{j,k}(8,3))-(Q{j,k}(4,2)*D{j,k}(10,3))+(Q{j,k}(4,3)*D{j,k}(8,3))+(Q{j,k}(4,4)*(D{j,k}(8,3)-D{j,k}(7,3))))*60*60*24/1000;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [11 16 19]
        icount = 4;
        for i = 9:2:17
            icount = icount + 1;
            pDOC{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*DelDOC{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*DelDOC{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24/1000;
        end
    end
end
% 70: i = [29]
% River box: single layer flow
for j = 1:1002
    for k = [29]
        for i = 2:4
            pDOC{j,k}(1,1) = ((DelDOCAvg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24/1000;
            pDOC{j,k}(i,1) = ((DelDOCAvg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(1:4,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary: pDOC surface and pDOC bottom
for j = 1:1002
    for k = [29]
        pDOC{j,k}(5,1) = ((Vol.Sur{j}(5,k)*DelDOC{j,k}(9,3))-((R(k,j)+sum(PBoxes(1:4,k))-sum(EBoxes(1:4,k)))*DAvg{j,k}(4,3))-(Q{j,k}(5,3)*D{j,k}(10,3))-(Q{j,k}(5,4)*(D{j,k}(10,3)-D{j,k}(9,3)))+((Q{j,k}(5,1)+PBoxes(5,k)-EBoxes(5,k))*D{j,k}(9,3)))*60*60*24/1000;
        pDOC{j,k}(5,2) = ((Vol.Bot{j}(5,k)*DelDOC{j,k}(10,3))-(Q{j,k}(5,2)*D{j,k}(12,3))+(Q{j,k}(5,3)*D{j,k}(10,3))+(Q{j,k}(5,4)*(D{j,k}(10,3)-D{j,k}(9,3))))*60*60*24/1000;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [29]
        icount = 5;
        for i = 11:2:17
            icount = icount + 1;
            pDOC{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*DelDOC{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*DelDOC{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24/1000;
        end
    end
end
% 100: i = [13 15]
% River box: single layer flow
for j = 1:1002
    for k = [13 15]
        for i = 2:5
            pDOC{j,k}(1,1) = ((DelDOCAvg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24/1000;
            pDOC{j,k}(i,1) = ((DelDOCAvg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(1:5,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary: pDOC surface and pDOC bottom
for j = 1:1002
    for k = [13 15]
        pDOC{j,k}(6,1) = ((Vol.Sur{j}(6,k)*DelDOC{j,k}(11,3))-((R(k,j)+sum(PBoxes(1:5,k))-sum(EBoxes(1:5,k)))*DAvg{j,k}(5,3))-(Q{j,k}(6,3)*D{j,k}(12,3))-(Q{j,k}(6,4)*(D{j,k}(12,3)-D{j,k}(11,3)))+((Q{j,k}(6,1)+PBoxes(6,k)-EBoxes(6,k))*D{j,k}(11,3)))*60*60*24/1000;
        pDOC{j,k}(6,2) = ((Vol.Bot{j}(6,k)*DelDOC{j,k}(12,3))-(Q{j,k}(6,2)*D{j,k}(14,3))+(Q{j,k}(6,3)*D{j,k}(12,3))+(Q{j,k}(6,4)*(D{j,k}(12,3)-D{j,k}(11,3))))*60*60*24/1000;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [13 15]
        icount = 6;
        for i = 13:2:17
            icount = icount + 1;
            pDOC{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*DelDOC{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*DelDOC{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24/1000;
        end
    end
end
% 120: i = [28]
% River box: single layer flow
for j = 1:1002
    for k = [28]
        for i = 2:6
            pDOC{j,k}(1,1) = ((DelDOCAvg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24/1000;
            pDOC{j,k}(i,1) = ((DelDOCAvg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(1:6,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary: pDOC surface and pDOC bottom
for j = 1:1002
    for k = [28]
        pDOC{j,k}(7,1) = ((Vol.Sur{j}(7,k)*DelDOC{j,k}(13,3))-((R(k,j)+sum(PBoxes(1:6,k))-sum(EBoxes(1:6,k)))*DAvg{j,k}(6,3))-(Q{j,k}(7,3)*D{j,k}(14,3))-(Q{j,k}(7,4)*(D{j,k}(14,3)-D{j,k}(13,3)))+((Q{j,k}(7,1)+PBoxes(7,k)-EBoxes(7,k))*D{j,k}(13,3)))*60*60*24/1000;
        pDOC{j,k}(7,2) = ((Vol.Bot{j}(7,k)*DelDOC{j,k}(14,3))-(Q{j,k}(7,2)*D{j,k}(16,3))+(Q{j,k}(7,3)*D{j,k}(14,3))+(Q{j,k}(7,4)*(D{j,k}(14,3)-D{j,k}(13,3))))*60*60*24/1000;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [28]
        icount = 7;
        for i = 15:2:17
            icount = icount + 1;
            pDOC{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*DelDOC{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*DelDOC{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24/1000;
        end
    end
end
% 140: i = [12]
% River box: single layer flow
for j = 1:1002
    for k = [12]
        for i = 2:7
            pDOC{j,k}(1,1) = ((DelDOCAvg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24/1000;
            pDOC{j,k}(i,1) = ((DelDOCAvg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(1:7,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary: pDOC surface and pDOC bottom
for j = 1:1002
    for k = [12]
        pDOC{j,k}(8,1) = ((Vol.Sur{j}(8,k)*DelDOC{j,k}(15,3))-((R(k,j)+sum(PBoxes(1:7,k))-sum(EBoxes(1:7,k)))*DAvg{j,k}(7,3))-(Q{j,k}(8,3)*D{j,k}(16,3))-(Q{j,k}(8,4)*(D{j,k}(16,3)-D{j,k}(15,3)))+((Q{j,k}(8,1)+PBoxes(8,k)-EBoxes(8,k))*D{j,k}(15,3)))*60*60*24/1000;
        pDOC{j,k}(8,2) = ((Vol.Bot{j}(8,k)*DelDOC{j,k}(16,3))-(Q{j,k}(8,2)*D{j,k}(18,3))+(Q{j,k}(8,3)*D{j,k}(16,3))+(Q{j,k}(8,4)*(D{j,k}(16,3)-D{j,k}(15,3))))*60*60*24/1000;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [12]
        icount = 8;
        for i = 17
            icount = icount + 1;
            pDOC{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*DelDOC{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24/1000;
            pDOC{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*DelDOC{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24/1000;
        end
    end
end

% Add surface and bottom boxes to get total box term
for j = 1:1002
    icount = 0;
    for k = 1:34
        for i = 1:9
            icount = icount + 1;
            pDOC2.StaTot (icount,j) = sum(pDOC{j,k}(i,1:2),'omitnan');
        end
    end
end

% Sum processing term for each time period (across the summed boxes)
% Sum processing term for each time period: Sta 20-160
for j = 1:1002
    icount = 0;
    for k = 1:9:306
        icount = icount + 1;
        pDOC2.SumTot (icount,j) = sum(pDOC2.StaTot(k:k+8,j),'omitnan');
    end
end
% Calculate mean and CI
for i = 1:34
    pDOC2.SumTotMean(i,1) = nanmean(pDOC2.SumTot(i,:));
    SEM (i,1) = nanstd(pDOC2.SumTot(i,:))/sqrt(1002);
    ts = tinv ([0.05 0.95], 1001);
    pDOC2.SumTotMean(i,2:3) = (nanmean(pDOC2.SumTot(i,:)))+(ts*SEM(i,1));
    pDOC2.SumTotMean(i,4) = pDOC2.SumTotMean(i,1)-pDOC2.SumTotMean(i,2);
end

% Plot
figure
errorbar (time,pDOC2.SumTotMean(:,1),pDOC2.SumTotMean(:,4))

save 'DOC_BoxModel_Final.mat'