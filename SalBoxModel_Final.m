% Script to calculate salinity box model following Hagy et al., 2000
% To calculate flow into/out of boxes for the entire NRE (from station 20 to 160) using salinity
% Must manually designate where the NRE begins to act as an estuary following the criteria:
%   Sal B > 0.5
%   SalB-SalS > 0.5
%   OR: SalS >0.5
% A.G. Hounshell (ahounshell10@gmail.com), 28 Dec 2018
% INSERT FULL CITATION HERE

%% Load in data
% Evaporation/precipitation data obtained from KEWN, New Bern, NC
% units: daily sum (m)
[Evap.data, Evap.parms, Evap.raw] = xlsread ('EvapPrecip.xlsx');
% Convert Excel date to Matlab date
Evap.date = datenum (Evap.raw(2:732,1), 'mm/dd/yyyy');

% River Flow from Ft. Barnwell, NC USGS Gage: 02091814
% Load in flows at Ft. Barnwell (ft^3/s)
[Dis.data, Dis.parms, Dis.raw] = xlsread ('FtBarnwell_Discharge_ExcelDate.xlsx');
% Convert date from excel date to matlab date
Dis.data(:,1)=x2mdate(Dis.data(:,1));
% convert from ft3/s to m3/s and then scale freshwater discharge to account for 31% of the watershed that is not gauged (Peirels et al., 2012) 
Dis.data(:,2)=0.0283168*Dis.data(:,2)/0.69;

% Use random number generator to estimate values that are within the %14
% variability of discharge measurements: for 1000+ different model
% runs/estimations
for j = 3:1003
    for i = 1:731
        a = Dis.data(i,2) - (Dis.data(i,2)*0.14);
        b = Dis.data(i,2) + (Dis.data(i,2)*0.14);
        Dis.data(i,j) = (b-a).*rand(1,1) + a;
    end
end

% Load in volume for each box: accounts for varying
% pycnocline depths over time
% Units: m^3
[Vol.data, Vol.parms, Vol.raw] = xlsread ('Volume_SandB.xlsx');
% Add variability to the volume data: assumed to be 10% variability
% Separate surface and bottom data
Vol.s = Vol.data(:,2);
Vol.b = Vol.data(:,3);
% Then add variability
for j = 2:1002
    for i = 1:306
        a = Vol.s(i,1) - (Vol.s(i,1)*0.10);
        b = Vol.s(i,1) + (Vol.s(i,1)*0.10);
        Vol.s(i,j) = (b-a).*rand(1,1) + a;
    end
end
for j = 2:1002
    for i = 1:306
        a = Vol.b(i,1) - (Vol.b(i,1)*0.10);
        b = Vol.b(i,1) + (Vol.b(i,1)*0.10);
        Vol.b(i,j) = (b-a).*rand(1,1) + a;
    end
end

% Load in salininty data: used for salinity data and to calculate Delta
% Salnity for each time point
[DelSal.data, DelSal.parms, DelSal.raw] = xlsread ('Data_Sal.xlsx');
% Convert excel date to matlab datenum
DelSal.time = datenum(DelSal.raw(2:701), 'mm/dd/yyyy');
% Add variabilty to the DelSal data: 10% variability
for j = 5:1005
    for i = 1:700
        a = DelSal.data(i,4) - (DelSal.data(i,4)*0.1);
        b = DelSal.data(i,4) + (DelSal.data(i,4)*0.1);
        DelSal.data(i,j) = (b-a).*rand(1,1) + a;
    end
end
% Need to constrain the 160S and 180B values for time points #2-7
% (Adding the 10% variabilty resulted in surface salinity > bottom salinity; this corrects for this)
% 160S: Constrain maximum variabilty to 5% of true value
for j = 5:1005
    for i = 37:20:140
        a = DelSal.data(i,4) - (DelSal.data(i,4)*0.1);
        b = DelSal.data(i,4) + (DelSal.data(i,4)*0.05);
        DelSal.data(i,j) = (b-a).*rand(1,1) + a;
    end
end
% 180B: Constrain minimum variability to 5% of true value
for j = 5:1005
    for i = 40:20:140
        a = DelSal.data(i,4) - (DelSal.data(i,4)*0.05);
        b = DelSal.data(i,4) + (DelSal.data(i,4)*0.1);
        DelSal.data(i,j) = (b-a).*rand(1,1) + a;
    end
end

% Sampling dates: pull out sampling dates from data
time = (DelSal.time(1:20:700));

%% Organize River flow (name as 'R')
% Find flow dates (USGS) that match up with sampling dates (ModMon sampling dates)
for i=1:length(time)
    x = find(Dis.data(:,1)==time(i));
    spots(i)=x; 
end
% Find average discharge over the sampling interval between ModMon runs
icount = 0;
for j = 2:1003
    icount = icount + 1;
    for i = 2:35;
        R (i-1,icount) = nanmean (Dis.data((spots(i-1):spots(i)),j));
    end
end

%% Organize Precipitation and Evaporation data
% Calculate average precipitation and evaporation between ModMon runs (current units: m/d)
for i = 2:35;
    E (i-1,1) = nanmean (Evap.data(((spots(i-1)):spots(i)),4));
    P (i-1,1) = nanmean (Evap.data(((spots(i-1)):spots(i)),2));
end
% Convert evaporation and precipitation to m/s
E (:,1) = E(:,1)/(3600*24);
P (:,1) = P(:,1)/(3600*24);
% Then multiply evaporation and precipitation by the surface area of each
% box (for each day); from ArcGIS Estuarine Shoreline for each ModMon box
Vol.Surf = [4488820; 8121578; 11444529; 15118923; 29564031; 41605810; 38316127; 45171051; 77980312];
% Evaporation
for i = 1:34
    for j = 1:9
        EBoxes (j,i) = E(i,1)*Vol.Surf(j,1);
    end
end
% Precipitation
for i = 1:34
    for j = 1:9
        PBoxes (j,i) = P(i,1)*Vol.Surf(j,1);
    end
end

%% Separate salinity by date
jcount = 0;
for j = 4:1005
    jcount = 1 + jcount;
    icount = 0;
    for i = 21:20:700
        icount = icount + 1;
        Salinity{jcount,icount} (:,1) = DelSal.data(i:i+19,1);
        Salinity{jcount,icount} (:,2) = DelSal.data(i:i+19,3);
        Salinity{jcount,icount} (:,3) = DelSal.data(i:i+19,j);
    end
end

%% Also need to calculate the change in salinity for each box
for j = 4:1005
    icount = 0;
    for i = 21:700
        icount = icount + 1;
        DelSal.Calc (icount,j-3) = (DelSal.data(i,j)-DelSal.data(i-20,j))/((DelSal.time(i,1)-DelSal.time(i-20,1))*24*60*60);
    end
end
% Then separate by date
jcount = 0;
for j = 1:1002
    jcount = 1 + jcount;
    icount = 0;
    for i = 1:20:680
        icount = icount + 1;
        DelSalinity{jcount,icount} (:,1) = DelSal.data(i:i+19,1);
        DelSalinity{jcount,icount} (:,2) = DelSal.data(i:i+19,3);
        DelSalinity{jcount,icount} (:,3) = DelSal.Calc(i:i+19,j);
    end
end

%% Separate out the surface and bottom box volumes
icount = 0;
for j = 1:1002
    icount = 0;
    for i = 1:9:306
        icount = icount + 1;
        Vol.Sur{j} (:,icount) = Vol.s(i:i+8,j);
    end
end
icount = 0;
for j = 1:1002
    icount = 0;
    for i = 1:9:306
        icount = icount + 1;
        Vol.Bot{j} (:,icount) = Vol.b(i:i+8,j);
    end
end

%% Calculate flow for each time period
for j = 1:1002
%% Calculate for each 'start' of the estuary: 20S
% 20: i = [3 4 5 6 8]
% Transition Box: Qm, Qm', Qvm, Evm
for k = [3 4 5 6 8]
    Q{j,k}(1,1) = (R(k,j)+PBoxes(1,k)-EBoxes(1,k))+(((Vol.Sur{j}(1,k)*DelSalinity{j,k}(1,3))+(Vol.Bot{j}(1,k)*DelSalinity{j,k}(2,3))+(Salinity{j,k}(1,3)*(R(k,j)+PBoxes(1,k)-EBoxes(1,k))))/(Salinity{j,k}(4,3)-Salinity{j,k}(1,3)));
    Q{j,k}(1,2) = (((Vol.Sur{j}(1,k)*DelSalinity{j,k}(1,3))+(Vol.Bot{j}(1,k)*DelSalinity{j,k}(2,3))+(Salinity{j,k}(1,3)*(R(k,j)+PBoxes(1,k)-EBoxes(1,k))))/(Salinity{j,k}(4,3)-Salinity{j,k}(1,3)));
    Q{j,k}(1,3) = Q{j,k}(1,2);
    Q{j,k}(1,4) = ((Vol.Sur{j}(1,k)*DelSalinity{j,k}(1,3))-(Q{j,k}(1,3)*Salinity{j,k}(2,3))+(Q{j,k}(1,1)*Salinity{j,k}(1,3)))/(Salinity{j,k}(2,3)-Salinity{j,k}(1,3));
end
% Estuarine box: Qm, Qm', Qvm, Evm
for k = [3 4 5 6 8]
    icount = 1;
    for i = 3:2:17
        icount = icount + 1;
        Q{j,k}(icount,1) = Q{j,k}(icount-1,1)+PBoxes(icount,k)-EBoxes(icount,k)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,2) = Q{j,k}(icount-1,2)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,3) = (((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,4) = ((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))-(Q{j,k}(icount-1,1)*Salinity{j,k}(i-2,3))+(Q{j,k}(icount,1)*Salinity{j,k}(i,3))-(Q{j,k}(icount,3)*Salinity{j,k}(i+1,3)))/(Salinity{j,k}(i+1,3)-Salinity{j,k}(i,3));
    end
end
for k = [3 4 5 6 8]
    Q160.s (k,j) = Q{j,k}(9,1);
    Q160.b (k,j) = Q{j,k}(9,2);
end
%% Calculate for each 'start' in the estuary: 30S
% 30: k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
% Transition Box: Qm, Qm', Qvm, Evm
for k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
    Q{j,k}(2,1) = (R(k,j)+sum(PBoxes(1:2,k))-sum(EBoxes(1:2,k)))+(((Vol.Sur{j}(2,k)*DelSalinity{j,k}(3,3))+(Vol.Bot{j}(2,k)*DelSalinity{j,k}(4,3))+(Salinity{j,k}(3,3)*(R(k,j)+sum(PBoxes(1:2,k))-sum(EBoxes(1:2,k)))))/(Salinity{j,k}(6,3)-Salinity{j,k}(3,3)));
    Q{j,k}(2,2) = (((Vol.Sur{j}(2,k)*DelSalinity{j,k}(3,3))+(Vol.Bot{j}(2,k)*DelSalinity{j,k}(4,3))+(Salinity{j,k}(3,3)*(R(k,j)+sum(PBoxes(1:2,k))-sum(EBoxes(1:2,k)))))/(Salinity{j,k}(6,3)-Salinity{j,k}(3,3)));
    Q{j,k}(2,3) = Q{j,k}(2,2);
    Q{j,k}(2,4) = ((Vol.Sur{j}(2,k)*DelSalinity{j,k}(3,3))-(Q{j,k}(2,3)*Salinity{j,k}(4,3))+(Q{j,k}(2,1)*Salinity{j,k}(3,3)))/(Salinity{j,k}(4,3)-Salinity{j,k}(3,3));
end
% Estuarine box: Qm, Qm', Qvm, Evm
for k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
    icount = 2;
    for i = 5:2:17
        icount = icount + 1;
        Q{j,k}(icount,1) = Q{j,k}(icount-1,1)+PBoxes(icount,k)-EBoxes(icount,k)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,2) = Q{j,k}(icount-1,2)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,3) = (((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,4) = ((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))-(Q{j,k}(icount-1,1)*Salinity{j,k}(i-2,3))+(Q{j,k}(icount,1)*Salinity{j,k}(i,3))-(Q{j,k}(icount,3)*Salinity{j,k}(i+1,3)))/(Salinity{j,k}(i+1,3)-Salinity{j,k}(i,3));
    end
end
for k = [1 2 7 10 18 20 21 22 23 24 25 26 31 33 34]
    Q160.s (k,j) = Q{j,k}(9,1);
    Q160.b (k,j) = Q{j,k}(9,2);
end
%% Calculate for start of each box: 50S
% 50: i = [9 14 17 27 30 32]
% Transition Box: Qm, Qm', Qvm, Evm
for k = [9 14 17 27 30 32]
    Q{j,k}(3,1) = (R(k,j)+sum(PBoxes(1:3,k))-sum(EBoxes(1:3,k)))+(((Vol.Sur{j}(3,k)*DelSalinity{j,k}(5,3))+(Vol.Bot{j}(3,k)*DelSalinity{j,k}(6,3))+(Salinity{j,k}(5,3)*(R(k,j)+sum(PBoxes(1:3,k))-sum(EBoxes(1:3,k)))))/(Salinity{j,k}(8,3)-Salinity{j,k}(5,3)));
    Q{j,k}(3,2) = (((Vol.Sur{j}(3,k)*DelSalinity{j,k}(5,3))+(Vol.Bot{j}(3,k)*DelSalinity{j,k}(6,3))+(Salinity{j,k}(5,3)*(R(k,j)+sum(PBoxes(1:3,k))-sum(EBoxes(1:3,k)))))/(Salinity{j,k}(8,3)-Salinity{j,k}(5,3)));
    Q{j,k}(3,3) = Q{j,k}(3,2);
    Q{j,k}(3,4) = ((Vol.Sur{j}(3,k)*DelSalinity{j,k}(5,3))-(Q{j,k}(3,3)*Salinity{j,k}(6,3))+(Q{j,k}(3,1)*Salinity{j,k}(5,3)))/(Salinity{j,k}(6,3)-Salinity{j,k}(5,3));
end
% Estuarine box: Qm, Qm', Qvm, Evm
for k = [9 14 17 27 30 32]
    icount = 3;
    for i = 7:2:17
        icount = icount + 1;
        Q{j,k}(icount,1) = Q{j,k}(icount-1,1)+PBoxes(icount,k)-EBoxes(icount,k)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,2) = Q{j,k}(icount-1,2)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,3) = (((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,4) = ((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))-(Q{j,k}(icount-1,1)*Salinity{j,k}(i-2,3))+(Q{j,k}(icount,1)*Salinity{j,k}(i,3))-(Q{j,k}(icount,3)*Salinity{j,k}(i+1,3)))/(Salinity{j,k}(i+1,3)-Salinity{j,k}(i,3));
    end
end
for k = [9 14 17 27 30 32]
    Q160.s (k,j) = Q{j,k}(9,1);
    Q160.b (k,j) = Q{j,k}(9,2);
end
%% Calculate for each box: 60S
% 60: i = [11 16 19]
% Transition Box: Qm, Qm', Qvm, Evm
for k = [11 16 19]
    Q{j,k}(4,1) = (R(k,j)+sum(PBoxes(1:4,k))-sum(EBoxes(1:4,k)))+(((Vol.Sur{j}(4,k)*DelSalinity{j,k}(7,3))+(Vol.Bot{j}(4,k)*DelSalinity{j,k}(8,3))+(Salinity{j,k}(7,3)*(R(k,j)+sum(PBoxes(1:4,k))-sum(EBoxes(1:4,k)))))/(Salinity{j,k}(10,3)-Salinity{j,k}(7,3)));
    Q{j,k}(4,2) = (((Vol.Sur{j}(4,k)*DelSalinity{j,k}(7,3))+(Vol.Bot{j}(4,k)*DelSalinity{j,k}(8,3))+(Salinity{j,k}(7,3)*(R(k,j)+sum(PBoxes(1:4,k))-sum(EBoxes(1:4,k)))))/(Salinity{j,k}(10,3)-Salinity{j,k}(7,3)));
    Q{j,k}(4,3) = Q{j,k}(4,2);
    Q{j,k}(4,4) = ((Vol.Sur{j}(4,k)*DelSalinity{j,k}(7,3))-(Q{j,k}(4,3)*Salinity{j,k}(8,3))+(Q{j,k}(4,1)*Salinity{j,k}(7,3)))/(Salinity{j,k}(8,3)-Salinity{j,k}(7,3));
end
% Estuarine box: Qm, Qm', Qvm, Evm
for k = [11 16 19]
    icount = 4;
    for i = 9:2:17
        icount = icount + 1;
        Q{j,k}(icount,1) = Q{j,k}(icount-1,1)+PBoxes(icount,k)-EBoxes(icount,k)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,2) = Q{j,k}(icount-1,2)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,3) = (((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,4) = ((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))-(Q{j,k}(icount-1,1)*Salinity{j,k}(i-2,3))+(Q{j,k}(icount,1)*Salinity{j,k}(i,3))-(Q{j,k}(icount,3)*Salinity{j,k}(i+1,3)))/(Salinity{j,k}(i+1,3)-Salinity{j,k}(i,3));
    end
end
for k = [11 16 19]
    Q160.s (k,j) = Q{j,k}(9,1);
    Q160.b (k,j) = Q{j,k}(9,2);
end
%% Calculate for each estuarine start box: 70S
% 70: i = [29]
% Transition Box: Qm, Qm', Qvm, Evm
for k = [29]
    Q{j,k}(5,1) = (R(k,j)+sum(PBoxes(1:5,k))-sum(EBoxes(1:5,k)))+(((Vol.Sur{j}(5,k)*DelSalinity{j,k}(9,3))+(Vol.Bot{j}(5,k)*DelSalinity{j,k}(10,3))+(Salinity{j,k}(9,3)*(R(k,j)+sum(PBoxes(1:5,k))-sum(EBoxes(1:5,k)))))/(Salinity{j,k}(12,3)-Salinity{j,k}(9,3)));
    Q{j,k}(5,2) = (((Vol.Sur{j}(5,k)*DelSalinity{j,k}(9,3))+(Vol.Bot{j}(5,k)*DelSalinity{j,k}(10,3))+(Salinity{j,k}(9,3)*(R(k,j)+sum(PBoxes(1:5,k))-sum(EBoxes(1:5,k)))))/(Salinity{j,k}(12,3)-Salinity{j,k}(9,3)));
    Q{j,k}(5,3) = Q{j,k}(5,2);
    Q{j,k}(5,4) = ((Vol.Sur{j}(5,k)*DelSalinity{j,k}(9,3))-(Q{j,k}(5,3)*Salinity{j,k}(10,3))+(Q{j,k}(5,1)*Salinity{j,k}(9,3)))/(Salinity{j,k}(10,3)-Salinity{j,k}(9,3));
end
% Estuarine box: Qm, Qm', Qvm, Evm
for k = [29]
    icount = 5;
    for i = 11:2:17
        icount = icount + 1;
        Q{j,k}(icount,1) = Q{j,k}(icount-1,1)+PBoxes(icount,k)-EBoxes(icount,k)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,2) = Q{j,k}(icount-1,2)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,3) = (((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,4) = ((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))-(Q{j,k}(icount-1,1)*Salinity{j,k}(i-2,3))+(Q{j,k}(icount,1)*Salinity{j,k}(i,3))-(Q{j,k}(icount,3)*Salinity{j,k}(i+1,3)))/(Salinity{j,k}(i+1,3)-Salinity{j,k}(i,3));
    end
end
for k = [29]
    Q160.s (k,j) = Q{j,k}(9,1);
    Q160.b (k,j) = Q{j,k}(9,2);
end
%% Calculate for each start of estuary: 100S
% 100: i = [13 15]
% Transition Box: Qm, Qm', Qvm, Evm
for k = [13 15]
    Q{j,k}(6,1) = (R(k,j)+sum(PBoxes(1:6,k))-sum(EBoxes(1:6,k)))+(((Vol.Sur{j}(6,k)*DelSalinity{j,k}(11,3))+(Vol.Bot{j}(6,k)*DelSalinity{j,k}(12,3))+(Salinity{j,k}(11,3)*(R(k,j)+sum(PBoxes(1:6,k))-sum(EBoxes(1:6,k)))))/(Salinity{j,k}(14,3)-Salinity{j,k}(11,3)));
    Q{j,k}(6,2) = (((Vol.Sur{j}(6,k)*DelSalinity{j,k}(11,3))+(Vol.Bot{j}(6,k)*DelSalinity{j,k}(12,3))+(Salinity{j,k}(11,3)*(R(k,j)+sum(PBoxes(1:6,k))-sum(EBoxes(1:6,k)))))/(Salinity{j,k}(14,3)-Salinity{j,k}(11,3)));
    Q{j,k}(6,3) = Q{j,k}(6,2);
    Q{j,k}(6,4) = ((Vol.Sur{j}(6,k)*DelSalinity{j,k}(11,3))-(Q{j,k}(6,3)*Salinity{j,k}(12,3))+(Q{j,k}(6,1)*Salinity{j,k}(11,3)))/(Salinity{j,k}(12,3)-Salinity{j,k}(11,3));
end
% Estuarine box: Qm, Qm', Qvm, Evm
for k = [13 15]
    icount = 6;
    for i = 13:2:17
        icount = icount + 1;
        Q{j,k}(icount,1) = Q{j,k}(icount-1,1)+PBoxes(icount,k)-EBoxes(icount,k)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,2) = Q{j,k}(icount-1,2)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,3) = (((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,4) = ((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))-(Q{j,k}(icount-1,1)*Salinity{j,k}(i-2,3))+(Q{j,k}(icount,1)*Salinity{j,k}(i,3))-(Q{j,k}(icount,3)*Salinity{j,k}(i+1,3)))/(Salinity{j,k}(i+1,3)-Salinity{j,k}(i,3));
    end
end
for k = [13 15]
    Q160.s (k,j) = Q{j,k}(9,1);
    Q160.b (k,j) = Q{j,k}(9,2);
end
%% Calculate for each estuarine start box: 120S
% 120: i = [28]
% Transition Box: Qm, Qm', Qvm, Evm
for k = [28]
    Q{j,k}(7,1) = (R(k,j)+sum(PBoxes(1:7,k))-sum(EBoxes(1:7,k)))+(((Vol.Sur{j}(7,k)*DelSalinity{j,k}(13,3))+(Vol.Bot{j}(7,k)*DelSalinity{j,k}(14,3))+(Salinity{j,k}(13,3)*(R(k,j)+sum(PBoxes(1:7,k))-sum(EBoxes(1:7,k)))))/(Salinity{j,k}(16,3)-Salinity{j,k}(13,3)));
    Q{j,k}(7,2) = (((Vol.Sur{j}(7,k)*DelSalinity{j,k}(13,3))+(Vol.Bot{j}(7,k)*DelSalinity{j,k}(14,3))+(Salinity{j,k}(13,3)*(R(k,j)+sum(PBoxes(1:7,k))-sum(EBoxes(1:7,k)))))/(Salinity{j,k}(16,3)-Salinity{j,k}(13,3)));
    Q{j,k}(7,3) = Q{j,k}(7,2);
    Q{j,k}(7,4) = ((Vol.Sur{j}(7,k)*DelSalinity{j,k}(13,3))-(Q{j,k}(7,3)*Salinity{j,k}(14,3))+(Q{j,k}(7,1)*Salinity{j,k}(13,3)))/(Salinity{j,k}(14,3)-Salinity{j,k}(13,3));
end
% Estuarine box: Qm, Qm', Qvm, Evm
for k = [28]
    icount = 7;
    for i = 15:2:17
        icount = icount + 1;
        Q{j,k}(icount,1) = Q{j,k}(icount-1,1)+PBoxes(icount,k)-EBoxes(icount,k)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,2) = Q{j,k}(icount-1,2)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,3) = (((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,4) = ((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))-(Q{j,k}(icount-1,1)*Salinity{j,k}(i-2,3))+(Q{j,k}(icount,1)*Salinity{j,k}(i,3))-(Q{j,k}(icount,3)*Salinity{j,k}(i+1,3)))/(Salinity{j,k}(i+1,3)-Salinity{j,k}(i,3));
    end
end
for k = [28]
    Q160.s (k,j) = Q{j,k}(9,1);
    Q160.b (k,j) = Q{j,k}(9,2);
end
%% Calculate for each box: 140S
% 140: i = [12]
% Transition Box: Qm, Qm', Qvm, Evm
for k = [12]
    Q{j,k}(8,1) = (R(k,j)+sum(PBoxes(1:8,k))-sum(EBoxes(1:8,k)))+(((Vol.Sur{j}(8,k)*DelSalinity{j,k}(15,3))+(Vol.Bot{j}(8,k)*DelSalinity{j,k}(16,3))+(Salinity{j,k}(15,3)*(R(k,j)+sum(PBoxes(1:8,k))-sum(EBoxes(1:8,k)))))/(Salinity{j,k}(18,3)-Salinity{j,k}(15,3)));
    Q{j,k}(8,2) = (((Vol.Sur{j}(8,k)*DelSalinity{j,k}(15,3))+(Vol.Bot{j}(8,k)*DelSalinity{j,k}(16,3))+(Salinity{j,k}(15,3)*(R(k,j)+sum(PBoxes(1:8,k))-sum(EBoxes(1:8,k)))))/(Salinity{j,k}(18,3)-Salinity{j,k}(15,3)));
    Q{j,k}(8,3) = Q{j,k}(8,2);
    Q{j,k}(8,4) = ((Vol.Sur{j}(8,k)*DelSalinity{j,k}(15,3))-(Q{j,k}(8,3)*Salinity{j,k}(16,3))+(Q{j,k}(8,1)*Salinity{j,k}(15,3)))/(Salinity{j,k}(16,3)-Salinity{j,k}(15,3));
end
% Estuarine box: Qm, Qm', Qvm, Evm
for k = [12]
    icount = 8;
    for i = 17
        icount = icount + 1;
        Q{j,k}(icount,1) = Q{j,k}(icount-1,1)+PBoxes(icount,k)-EBoxes(icount,k)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,2) = Q{j,k}(icount-1,2)+(((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,3) = (((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))+(Vol.Bot{j}(icount,k)*DelSalinity{j,k}(i+1,3))+(Q{j,k}(icount-1,2)*(Salinity{j,k}(i+1,3)-Salinity{j,k}(i+3,3)))+(Q{j,k}(icount-1,1)*(Salinity{j,k}(i,3)-Salinity{j,k}(i-2,3)))+(Salinity{j,k}(i,3)*(PBoxes(icount,k)-EBoxes(icount,k))))/(Salinity{j,k}(i+3,3)-Salinity{j,k}(i,3)));
        Q{j,k}(icount,4) = ((Vol.Sur{j}(icount,k)*DelSalinity{j,k}(i,3))-(Q{j,k}(icount-1,1)*Salinity{j,k}(i-2,3))+(Q{j,k}(icount,1)*Salinity{j,k}(i,3))-(Q{j,k}(icount,3)*Salinity{j,k}(i+1,3)))/(Salinity{j,k}(i+1,3)-Salinity{j,k}(i,3));
    end
end
for k = [12]
    Q160.s (k,j) = Q{j,k}(9,1);
    Q160.b (k,j) = Q{j,k}(9,2);
end
end

%% Calculate means and confidence intervals for 160
% Calculate mean of Q160.s
for i = 1:34
    Q160.means (i,1) = nanmean(Q160.s(i,:));
end
% Calculate mean of Q160.b
for i = 1:34
    Q160.meanb (i,1) = nanmean(Q160.b(i,:));
end
% Calculate CI's for 160S
for i = 1:34
  SEM (i,1) = nanstd(Q160.s(i,:))/sqrt(1002);
  ts = tinv ([0.05 0.95], 1001);
  Q160.CIs (i,1:2) = (nanmean(Q160.s(i,:)))+(ts*SEM(i,1));
end
for i = 1:34
    Q160.CIs(i,3) = Q160.means(i,1)-Q160.CIs(i,1);
end
% Calculate CI's for 160B
for i = 1:34
  SEM (i,1) = nanstd(Q160.b(i,:))/sqrt(1002);
  ts = tinv ([0.05 0.95], 1001);
  Q160.CIb (i,1:2) = (nanmean(Q160.b(i,:)))+(ts*SEM(i,1));
end
for i = 1:34
    Q160.CIb(i,3) = Q160.meanb(i,1)-Q160.CIb(i,1);
end
% Calculate mean R
for i = 1:34
    Rmean (i,1) = nanmean (R(i,:));
end
% Plot
figure
errorbar (DelSal.time(21:20:700),Q160.means,Q160.CIs(:,3),'.-k','MarkerSize',20)
hold on
errorbar (DelSal.time(21:20:700),Q160.meanb,Q160.CIb(:,3),'^-k','MarkerSize',5, 'MarkerFaceColor', 'k')
hold on
plot (DelSal.time(21:20:700),Rmean,'o--k','MarkerSize',5)
for i = [4 7 9 11 12 14 17 19 28 33]
    hold on
    plot ([time(i,1) time(i,1)], [-500 3500], '--k')
end
legend ('160S','160B','R')
legend ('location', 'nw')
datetick ('x', 'mmm yy')
ylabel ('Discharge (m^3 S^-^1)')
xlabel ('Time')
xlim ([736165 736677])
set (gca, 'FontSize', 13)

% Then save with Q, R, Volumes, and Evaporation and Precipitation data (for DOC/a350 box model)
save 'ForOCBoxModel.mat'