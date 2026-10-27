clc;
clear;
close all;

disp('==============================================');
disp('   HEART RATE SIGNAL TREND ANALYSIS SYSTEM');
disp('==============================================');

%% 1. COLLECT PERSONAL AND MONITORING DATA

age = input('Enter age (years): ');
interval = input('Enter time between readings (minutes): ');
n = input('Enter the number of heart-rate readings: ');

while ~isscalar(age) || ~isfinite(age) || age < 1 || age > 120
    age = input('Enter a valid age: ');
end

while ~isscalar(interval) || ~isfinite(interval) || interval <= 0
    interval = input('Enter a positive time interval: ');
end

while ~isscalar(n) || ~isfinite(n) || n < 2 || n ~= floor(n)
    n = input('Enter a whole number of at least 2 readings: ');
end

activity = input(['Were readings taken while resting? ', ...
                  'Enter 1 for YES or 0 for NO: ']);

while ~isscalar(activity) || ~ismember(activity,[0 1])
    activity = input('Enter 1 for YES or 0 for NO: ');
end

%% 2. COLLECT HEART-RATE READINGS

hr = zeros(1,n);

disp(' ');
disp('Enter each measured heart rate in BPM.');

for k = 1:n
    prompt = sprintf('Reading %d of %d: ', k, n);
    hr(k) = input(prompt);

    while ~isscalar(hr(k)) || ~isfinite(hr(k)) || ...
            hr(k) <= 0 || hr(k) > 300
        disp('Enter a positive, valid numeric BPM value.');
        hr(k) = input(prompt);
    end
end

%% 3. CREATE TIME AXIS

time = (0:n-1) * interval;
duration = time(end);

%% 4. CALCULATE STATISTICS

avgHR = mean(hr);
minHR = min(hr);
maxHR = max(hr);
medianHR = median(hr);
stdHR = std(hr);

% Moving-average smoothing
window = max(1,round(5/interval));
smoothHR = movmean(hr,window);

% Percentage of readings above and below adult reference limits
high = hr > 100;
low = hr < 60;

highPercent = 100 * sum(high)/n;
lowPercent = 100 * sum(low)/n;

%% 5. CHECK SUSTAINED HIGH OR LOW READINGS

% Require a span of at least 5 minutes between first and last reading
required = ceil(5/interval) + 1;

sustainedHigh = false;
sustainedLow = false;

if n >= required
    for k = 1:(n-required+1)
        if all(high(k:k+required-1))
            sustainedHigh = true;
        end

        if all(low(k:k+required-1))
            sustainedLow = true;
        end
    end
end

%% 6. DISPLAY NUMERICAL ANALYSIS

disp(' ');
disp('==============================================');
disp('              ANALYSIS REPORT');
disp('==============================================');

fprintf('Age: %d years\n',age);
fprintf('Number of readings: %d\n',n);
fprintf('Sampling interval: %.2f minutes\n',interval);
fprintf('Monitoring duration: %.2f minutes\n',duration);

fprintf('\nAverage heart rate: %.2f BPM\n',avgHR);
fprintf('Median heart rate: %.2f BPM\n',medianHR);
fprintf('Minimum heart rate: %.2f BPM\n',minHR);
fprintf('Maximum heart rate: %.2f BPM\n',maxHR);
fprintf('Standard deviation: %.2f BPM\n',stdHR);

fprintf('Readings above 100 BPM: %.2f%%\n',highPercent);
fprintf('Readings below 60 BPM: %.2f%%\n',lowPercent);

%% 7. INTERPRETATION OF THE DATA

disp(' ');
disp('========== PATTERN INTERPRETATION ==========');

if n >= 2
    change = hr(end)-hr(1);
    fprintf('Change from first to last reading: %.2f BPM\n',change);

    if change > 5
        disp('Overall trend: Increasing.');
    elseif change < -5
        disp('Overall trend: Decreasing.');
    else
        disp('Overall trend: Relatively stable.');
    end
end

if activity == 1 && age >= 18
    if sustainedHigh
        disp(['FLAG: Heart rate remained above 100 BPM ', ...
              'for at least 5 minutes.']);
    elseif any(high)
        disp('Some resting readings exceeded 100 BPM.');
    else
        disp('No readings exceeded 100 BPM.');
    end

    if sustainedLow
        disp(['FLAG: Heart rate remained below 60 BPM ', ...
              'for at least 5 minutes.']);
    elseif any(low)
        disp('Some resting readings were below 60 BPM.');
    else
        disp('No readings were below 60 BPM.');
    end
else
    disp(['Adult resting thresholds are not used to ', ...
          'classify this data.']);
    disp(['Heart rate depends on age, activity, medication ', ...
          'and other factors.']);
end

disp(' ');
disp('POSSIBLE CONCERNS:');

if activity == 1 && age >= 18
    if sustainedHigh
        disp(['Persistent high resting heart rate may need ', ...
              'medical assessment, especially with symptoms.']);
    end

    if sustainedLow
        disp(['Persistent low resting heart rate may need ', ...
              'medical assessment depending on symptoms and context.']);
    end

    if ~sustainedHigh && ~sustainedLow
        disp(['No sustained threshold pattern was detected ', ...
              'using the selected rules.']);
    end
else
    disp(['No disease conclusion can be drawn from these ', ...
          'readings alone.']);
end

disp(['These flags are screening indicators, not a ', ...
      'diagnosis of a disease.']);

%% 8. GRAPH 1: ORIGINAL AND SMOOTHED SIGNAL

figure('Name','Heart Rate Trend Analysis', ...
       'NumberTitle','off');

subplot(2,1,1);

plot(time,hr,'b-','LineWidth',1.2);
hold on;
plot(time,smoothHR,'k-','LineWidth',2);

if age >= 18 && activity == 1
    yline(100,'r--','100 BPM');
    yline(60,'m--','60 BPM');
end

xlabel('Time (minutes)');
ylabel('Heart Rate (BPM)');
title('Original Signal and Smoothed Trend');
legend('Measured Heart Rate','Smoothed Trend', ...
       'Location','best');
grid on;
xlim([0 max(time(end),interval)]);

%% 9. GRAPH 2: FLAGGED READINGS

subplot(2,1,2);

plot(time,hr,'b-o','LineWidth',1, ...
     'MarkerSize',3);
hold on;

if age >= 18 && activity == 1
    plot(time(high),hr(high),'ro', ...
         'MarkerFaceColor','r','MarkerSize',6);
    plot(time(low),hr(low),'mo', ...
         'MarkerFaceColor','m','MarkerSize',6);

    yline(100,'r--','100 BPM');
    yline(60,'m--','60 BPM');

    legend('Heart Rate','Above 100 BPM', ...
           'Below 60 BPM','Location','best');
else
    legend('Heart Rate','Location','best');
end

xlabel('Time (minutes)');
ylabel('Heart Rate (BPM)');
title('Heart Rate Readings and Threshold Flags');
grid on;
xlim([0 max(time(end),interval)]);

disp(' ');
disp('Graphs generated successfully.');
disp('Analysis completed.');
