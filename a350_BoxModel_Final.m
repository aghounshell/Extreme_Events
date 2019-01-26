% Script to construct a350 box model: to calculate 'processing
% term' for each time period/box and explore a350 export from sta 160
% Includes 'adaptive' modeling to account for changes in the 'beginning' of
% the estuary
% A.G. Hounshell (ahounshell10@gmail.com), 29 Dec 2018

%% Load in data
% Load in data from salinity box model: ForOCBoxModel.mat
% Add total volume data for each station (in m^3)
Vol.Tot = [5947595; 18017248; 29805909; 39391374; 80377844; 138295695; 139773655; 172935830; 330397257];
% Add variability to volume data (10%)
for j = 2:1002
    for i = 1:9
        a = Vol.Tot(i,1) - (Vol.Tot(i,1)*0.1);
        b = Vol.Tot(i,1) + (Vol.Tot(i,1)*0.1);
        Vol.Tot(i,j) = (b-a).*rand(1,1) + a;
    end
end
% Load in a350 data
[data.data, data.parms, data.raw] = xlsread ('OCData_Calc.xlsx');
% Convert to matlab datenum
data.time = datenum(data.raw(2:771), 'mm/dd/yyyy');
time = data.time(23:22:770);
% Separate into data from sta 20-180: data from 7-6-2015
% a_350 data
icount = 1;
for i = 3:22:770
    a350.data (icount:icount+19,1) = data.data(i:i+19,1);
    a350.data (icount:icount+19,2) = data.data(i:i+19,3);
    a350.data (icount:icount+19,3) = data.data(i:i+19,5);
    icount = icount + 20;
end
% Separate data from sta 0: data from 7-20-15
icount = 1;
for i = 23:22:770
    zero.data (icount:icount+1,1) = data.data(i:i+1,3);
    zero.data (icount:icount+1,2) = data.data(i:i+1,5);
    icount = icount + 2;
end

% Add variability to Station 0 data: 11% for a_350 data
for j = 3:1003
    for i = 1:68
        a = zero.data(i,2) - (zero.data(i,2)*0.11);
        b = zero.data(i,2) + (zero.data(i,2)*0.11);
        zero.data(i,j) = (b-a).*rand(1,1) + a;
    end
end

% Average surface and bottom concentrations for station zero
for j = 2:1003
    icount = 0;
    for i = 1:2:68
        icount = icount + 1;
        zero.Avg (icount,j-1) = nanmean(zero.data(i:i+1,j));
    end
end

% Add variabilty to the rest of the a_350 data: 11%
for j = 4:1004
    for i = 1:700
        a = a350.data(i,3) - (a350.data(i,3)*0.11);
        b = a350.data(i,3) + (a350.data(i,3)*0.11);
        a350.data(i,j) = (b-a).*rand(1,1) + a;
    end
end
% Average S and B for each station (for when the estuary acts as a river)
for j = 3:1004
    icount = 0;
    for i = 1:2:700
        icount = icount + 1;
        a350.avg(icount,1) = a350.data(i,1);
        a350.avg(icount,2) = 3;
        a350.avg(icount,j) = nanmean(a350.data(i:i+1,j));
    end
end

%% Separate a350 by date
jcount = 0;
for j = 3:1004
    jcount = 1 + jcount;
    icount = 0;
    for i = 21:20:700
        icount = icount + 1;
        D{jcount,icount} (:,1) = a350.data(i:i+19,1);
        D{jcount,icount} (:,2) = a350.data(i:i+19,2);
        D{jcount,icount} (:,3) = a350.data(i:i+19,j);
    end
end
% Separate a350 average by date
jcount = 0;
for j = 3:1004
    jcount = 1 + jcount;
    icount = 0;
    for i = 11:10:350
        icount = icount + 1;
        DAvg{jcount,icount} (:,1) = a350.avg(i:i+9,1);
        DAvg{jcount,icount} (:,2) = a350.avg(i:i+9,2);
        DAvg{jcount,icount} (:,3) = a350.avg(i:i+9,j);
    end
end

%% Also need to calculate the change in a350 for each box
icount = 1;
for i = 1:22:770
    a350.time (icount:icount+19,1) = data.time(i:i+19,1);
    icount = icount + 20;
end
for j = 3:1004
    icount = 0;
    for i = 21:700
        icount = icount + 1;
        a350.DelCalc (icount,j-2) = (a350.data(i,j)-a350.data(i-20,j))/((a350.time(i,1)-a350.time(i-20,1))*24*60*60);
    end
end
% Then separate by date
jcount = 0;
for j = 1:1002
    jcount = 1 + jcount;
    icount = 0;
    for i = 1:20:680
        icount = icount + 1;
        Dela350{jcount,icount} (:,1) = a350.data(i:i+19,1);
        Dela350{jcount,icount} (:,2) = a350.data(i:i+19,2);
        Dela350{jcount,icount} (:,3) = a350.DelCalc(i:i+19,j);
    end
end
% And calculate average a350 for each box:
icount = 1;
for i = 1:22:770
    a350.time2 (icount:icount+9,1) = data.time(i:2:i+19,1);
    icount = icount + 10;
end
for j = 3:1004
    icount = 0;
    for i = 11:350
        icount = icount + 1;
        a350.DelCalcAvg (icount,j-2) = (a350.avg(i,j)-a350.avg(i-10,j))/((a350.time2(i,1)-a350.time2(i-10,1))*24*60*60);
    end
end
% Then separate by date
jcount = 0;
for j = 1:1002
    jcount = 1 + jcount;
    icount = 0;
    for i = 1:10:340
        icount = icount + 1;
        Dela350Avg{jcount,icount} (:,1) = a350.avg(i:i+9,1);
        Dela350Avg{jcount,icount} (:,2) = a350.avg(i:i+9,2);
        Dela350Avg{jcount,icount} (:,3) = a350.DelCalcAvg(i:i+9,j);
    end
end

%% Then add a source/sink term to the a350 box model: pa350
% Need to change the location of where the estuary 'starts': can still
% calculate a source/sink term for 'river' boxes using the a350
% concentration into and out of the box
% In units of m^2/d
% 20: i = [3 4 5 6 8]
% Transition box: moving from river to estuary: 
for j = 1:1002
    for k = [3 4 5 6 8]
        pa350{j,k}(1,1) = ((Vol.Sur{j}(1,k)*Dela350{j,k}(1,3))-(R(k,j)*zero.Avg(k,j))-(Q{j,k}(1,3)*D{j,k}(2,3))-(Q{j,k}(1,4)*(D{j,k}(2,3)-D{j,k}(1,3)))+((Q{j,k}(1,1)+PBoxes(1,k)-EBoxes(1,k))*D{j,k}(1,3)))*60*60*24;
        pa350{j,k}(1,2) = ((Vol.Bot{j}(1,k)*Dela350{j,k}(2,3))-(Q{j,k}(1,2)*D{j,k}(4,3))+(Q{j,k}(1,3)*D{j,k}(2,3))+(Q{j,k}(1,4)*(D{j,k}(2,3)-D{j,k}(1,3))))*60*60*24;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [3 4 5 6 8]
        icount = 1;
        for i = 3:2:17
            icount = icount + 1;
            pa350{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*Dela350{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24;
            pa350{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*Dela350{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24;
        end
    end
end
% 30: k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
% River box: single layer flow, station 20
for j = 1:1002
    for k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
        for i = 1
            pa350{j,k}(i,1) = ((Dela350Avg{j,k}(i,3)*Vol.Tot(i,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24;
            pa350{j,k}(i,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary: station 30
for j = 1:1002
    for k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
        pa350{j,k}(2,1) = ((Vol.Sur{j}(2,k)*Dela350{j,k}(3,3))-((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3))-(Q{j,k}(2,3)*D{j,k}(4,3))-(Q{j,k}(2,4)*(D{j,k}(4,3)-D{j,k}(3,3)))+((Q{j,k}(2,1)+PBoxes(2,k)-EBoxes(2,k))*D{j,k}(3,3)))*60*60*24;
        pa350{j,k}(2,2) = ((Vol.Bot{j}(2,k)*Dela350{j,k}(4,3))-(Q{j,k}(2,2)*D{j,k}(6,3))+(Q{j,k}(2,3)*D{j,k}(4,3))+(Q{j,k}(2,4)*(D{j,k}(4,3)-D{j,k}(3,3))))*60*60*24;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
        icount = 2;
        for i = 5:2:17
            icount = icount + 1;
            pa350{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*Dela350{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24;
            pa350{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*Dela350{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24;
        end
    end
end
% 50: i = [9 14 17 27 30 32]
% River box: single layer flow
for j = 1:1002
    for k = [9 14 17 27 30 32]
        for i = 2
            pa350{j,k}(1,1) = ((Dela350Avg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24;
            pa350{j,k}(2,1) = ((Dela350Avg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(2,k)-EBoxes(2,k))*DAvg{j,k}(i,3)))*60*60*24;
            pa350{j,k}(1:2,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary:
for j = 1:1002
    for k = [9 14 17 27 30 32]
        pa350{j,k}(3,1) = ((Vol.Sur{j}(3,k)*Dela350{j,k}(5,3))-((R(k,j)+sum(PBoxes(1:2,k))-sum(EBoxes(1:2,k)))*DAvg{j,k}(2,3))-(Q{j,k}(3,3)*D{j,k}(6,3))-(Q{j,k}(3,4)*(D{j,k}(6,3)-D{j,k}(5,3)))+((Q{j,k}(3,1)+PBoxes(3,k)-EBoxes(3,k))*D{j,k}(5,3)))*60*60*24;
        pa350{j,k}(3,2) = ((Vol.Bot{j}(3,k)*Dela350{j,k}(6,3))-(Q{j,k}(3,2)*D{j,k}(8,3))+(Q{j,k}(3,3)*D{j,k}(6,3))+(Q{j,k}(3,4)*(D{j,k}(6,3)-D{j,k}(5,3))))*60*60*24;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [9 14 17 27 30 32]
        icount = 3;
        for i = 7:2:17
            icount = icount + 1;
            pa350{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*Dela350{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24;
            pa350{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*Dela350{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24;
        end
    end
end
% 60: i = [11 16 19]
% River box: single layer flow
for j = 1:1002
    for k = [11 16 19]
        for i = 2:3
            pa350{j,k}(1,1) = ((Dela350Avg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24;
            pa350{j,k}(i,1) = ((Dela350Avg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24;
            pa350{j,k}(1:3,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary:
for j = 1:1002
    for k = [11 16 19]
        pa350{j,k}(4,1) = ((Vol.Sur{j}(4,k)*Dela350{j,k}(7,3))-((R(k,j)+sum(PBoxes(1:3,k))-sum(EBoxes(1:3,k)))*DAvg{j,k}(3,3))-(Q{j,k}(4,3)*D{j,k}(8,3))-(Q{j,k}(4,4)*(D{j,k}(8,3)-D{j,k}(7,3)))+((Q{j,k}(4,1)+PBoxes(4,k)-EBoxes(4,k))*D{j,k}(7,3)))*60*60*24;
        pa350{j,k}(4,2) = ((Vol.Bot{j}(4,k)*Dela350{j,k}(8,3))-(Q{j,k}(4,2)*D{j,k}(10,3))+(Q{j,k}(4,3)*D{j,k}(8,3))+(Q{j,k}(4,4)*(D{j,k}(8,3)-D{j,k}(7,3))))*60*60*24;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [11 16 19]
        icount = 4;
        for i = 9:2:17
            icount = icount + 1;
            pa350{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*Dela350{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24;
            pa350{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*Dela350{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24;
        end
    end
end
% 70: i = [29]
% River box: single layer flow
for j = 1:1002
    for k = [29]
        for i = 2:4
            pa350{j,k}(1,1) = ((Dela350Avg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24;
            pa350{j,k}(i,1) = ((Dela350Avg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24;
            pa350{j,k}(1:4,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary:
for j = 1:1002
    for k = [29]
        pa350{j,k}(5,1) = ((Vol.Sur{j}(5,k)*Dela350{j,k}(9,3))-((R(k,j)+sum(PBoxes(1:4,k))-sum(EBoxes(1:4,k)))*DAvg{j,k}(4,3))-(Q{j,k}(5,3)*D{j,k}(10,3))-(Q{j,k}(5,4)*(D{j,k}(10,3)-D{j,k}(9,3)))+((Q{j,k}(5,1)+PBoxes(5,k)-EBoxes(5,k))*D{j,k}(9,3)))*60*60*24;
        pa350{j,k}(5,2) = ((Vol.Bot{j}(5,k)*Dela350{j,k}(10,3))-(Q{j,k}(5,2)*D{j,k}(12,3))+(Q{j,k}(5,3)*D{j,k}(10,3))+(Q{j,k}(5,4)*(D{j,k}(10,3)-D{j,k}(9,3))))*60*60*24;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [29]
        icount = 5;
        for i = 11:2:17
            icount = icount + 1;
            pa350{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*Dela350{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24;
            pa350{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*Dela350{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24;
        end
    end
end
% 100: i = [13 15]
% River box: single layer flow
for j = 1:1002
    for k = [13 15]
        for i = 2:5
            pa350{j,k}(1,1) = ((Dela350Avg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24;
            pa350{j,k}(i,1) = ((Dela350Avg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24;
            pa350{j,k}(1:5,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary:
for j = 1:1002
    for k = [13 15]
        pa350{j,k}(6,1) = ((Vol.Sur{j}(6,k)*Dela350{j,k}(11,3))-((R(k,j)+sum(PBoxes(1:5,k))-sum(EBoxes(1:5,k)))*DAvg{j,k}(5,3))-(Q{j,k}(6,3)*D{j,k}(12,3))-(Q{j,k}(6,4)*(D{j,k}(12,3)-D{j,k}(11,3)))+((Q{j,k}(6,1)+PBoxes(6,k)-EBoxes(6,k))*D{j,k}(11,3)))*60*60*24;
        pa350{j,k}(6,2) = ((Vol.Bot{j}(6,k)*Dela350{j,k}(12,3))-(Q{j,k}(6,2)*D{j,k}(14,3))+(Q{j,k}(6,3)*D{j,k}(12,3))+(Q{j,k}(6,4)*(D{j,k}(12,3)-D{j,k}(11,3))))*60*60*24;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [13 15]
        icount = 6;
        for i = 13:2:17
            icount = icount + 1;
            pa350{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*Dela350{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24;
            pa350{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*Dela350{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24;
        end
    end
end
% 120: i = [28]
% River box: single layer flow
for j = 1:1002
    for k = [28]
        for i = 2:6
            pa350{j,k}(1,1) = ((Dela350Avg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24;
            pa350{j,k}(i,1) = ((Dela350Avg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24;
            pa350{j,k}(1:6,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary:
for j = 1:1002
    for k = [28]
        pa350{j,k}(7,1) = ((Vol.Sur{j}(7,k)*Dela350{j,k}(13,3))-((R(k,j)+sum(PBoxes(1:6,k))-sum(EBoxes(1:6,k)))*DAvg{j,k}(6,3))-(Q{j,k}(7,3)*D{j,k}(14,3))-(Q{j,k}(7,4)*(D{j,k}(14,3)-D{j,k}(13,3)))+((Q{j,k}(7,1)+PBoxes(7,k)-EBoxes(7,k))*D{j,k}(13,3)))*60*60*24;
        pa350{j,k}(7,2) = ((Vol.Bot{j}(7,k)*Dela350{j,k}(14,3))-(Q{j,k}(7,2)*D{j,k}(16,3))+(Q{j,k}(7,3)*D{j,k}(14,3))+(Q{j,k}(7,4)*(D{j,k}(14,3)-D{j,k}(13,3))))*60*60*24;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [28]
        icount = 7;
        for i = 15:2:17
            icount = icount + 1;
            pa350{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*Dela350{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24;
            pa350{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*Dela350{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24;
        end
    end
end
% 140: i = [12]
% River box: single layer flow
for j = 1:1002
    for k = [12]
        for i = 2:7
            pa350{j,k}(1,1) = ((Dela350Avg{j,k}(1,3)*Vol.Tot(1,j))-(R(k,j)*zero.Avg(k,j))+((R(k,j)+PBoxes(1,k)-EBoxes(1,k))*DAvg{j,k}(1,3)))*60*60*24;
            pa350{j,k}(i,1) = ((Dela350Avg{j,k}(i,3)*Vol.Tot(i,j))-((R(k,j)+sum(PBoxes(1:i-1,k))-sum(EBoxes(1:i-1,k)))*DAvg{j,k}(i-1,3))+((R(k,j)+PBoxes(i,k)-EBoxes(i,k))*DAvg{j,k}(i,3)))*60*60*24;
            pa350{j,k}(1:7,2) = NaN;
        end
    end
end
% Transition box: moving from river to estuary:
for j = 1:1002
    for k = [12]
        pa350{j,k}(8,1) = ((Vol.Sur{j}(8,k)*Dela350{j,k}(15,3))-((R(k,j)+sum(PBoxes(1:7,k))-sum(EBoxes(1:7,k)))*DAvg{j,k}(7,3))-(Q{j,k}(8,3)*D{j,k}(16,3))-(Q{j,k}(8,4)*(D{j,k}(16,3)-D{j,k}(15,3)))+((Q{j,k}(8,1)+PBoxes(8,k)-EBoxes(8,k))*D{j,k}(15,3)))*60*60*24;
        pa350{j,k}(8,2) = ((Vol.Bot{j}(8,k)*Dela350{j,k}(16,3))-(Q{j,k}(8,2)*D{j,k}(18,3))+(Q{j,k}(8,3)*D{j,k}(16,3))+(Q{j,k}(8,4)*(D{j,k}(16,3)-D{j,k}(15,3))))*60*60*24;
    end
end
% Estuarine box: L surface; L bottom
for j = 1:1002
    for k = [12]
        icount = 8;
        for i = 17
            icount = icount + 1;
            pa350{j,k}(icount,1) = ((Vol.Sur{j}(icount,k)*Dela350{j,k}(i,3))-(Q{j,k}(icount-1,1)*D{j,k}(i-2,3))-(Q{j,k}(icount,3)*D{j,k}(i+1,3))-(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3)))+((Q{j,k}(icount,1)+PBoxes(icount,k)-EBoxes(icount,k))*D{j,k}(i,3)))*60*60*24;
            pa350{j,k}(icount,2) = ((Vol.Bot{j}(icount,k)*Dela350{j,k}(i+1,3))-(Q{j,k}(icount,2)*D{j,k}(i+3,3))+(Q{j,k}(icount-1,2)*D{j,k}(i+1,3))+(Q{j,k}(icount,3)*D{j,k}(i+1,3))+(Q{j,k}(icount,4)*(D{j,k}(i+1,3)-D{j,k}(i,3))))*60*60*24;
        end
    end
end

% Add surface and bottom boxes to get total box term
for j = 1:1002
    icount = 0;
    for k = 1:34
        for i = 1:9
            icount = icount + 1;
            pa3502.StaTot (icount,j) = sum(pa350{j,k}(i,1:2),'omitnan');
        end
    end
end
% Replace zero values with NaN
for j = 1:1002
    for k = 1:306
        if pa3502.StaTot(k,j) == 0
            pa3502.StaTot(k,j) = NaN;
        end
    end
end

% Sum processing term for each time period (across the summed boxes)
% Sum processing term for each time period: Sta 20-160
for j = 1:1002
    icount = 0;
    for k = 1:9:306
        icount = icount + 1;
        pa3502.SumTot (icount,j) = sum(pa3502.StaTot(k:k+8,j),'omitnan');
    end
end
% Calculate mean and CI
for i = 1:34
    pa3502.SumTotMean(i,1) = nanmean(pa3502.SumTot(i,:));
    SEM (i,1) = nanstd(pa3502.SumTot(i,:))/sqrt(1002);
    ts = tinv ([0.05 0.95], 1001);
    pa3502.SumTotMean(i,2:3) = (nanmean(pa3502.SumTot(i,:)))+(ts*SEM(i,1));
    pa3502.SumTotMean(i,4) = pa3502.SumTotMean(i,1)-pa3502.SumTotMean(i,2);
end

% Plot
figure
errorbar (time,pa3502.SumTotMean(:,1),pa3502.SumTotMean(:,4))

save 'a350_BoxModel_Final.mat'