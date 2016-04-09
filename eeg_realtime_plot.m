classdef eeg_realtime_plot < handle
    
    properties
        eeg = emotiv_epoc;
        figure_handle;
        line_handles;
        channels = [1,3,12,14];
        num_channels;
        timespan = 10;
        time;
        sensor_data;
    end
    
    methods
        
        function obj = eeg_realtime_plot()
            obj.figure_handle = figure;
            obj.num_channels = length(obj.channels);
            obj.time = 0:1/obj.eeg.FS:obj.timespan;
            obj.sensor_data = zeros(obj.num_channels,length(obj.time));
            
            for n = 1:obj.num_channels
                subplot(obj.num_channels, 1 , n)
                obj.line_handles(n) = line(obj.time, obj.sensor_data(n,:));
                ylabel(obj.eeg.CHANNEL_NAMES(obj.channels(n),:));

                if n < obj.num_channels
                    set(gca,'XTick',[])
                end 
            end
            
        xlabel('Time (s)')
        subplot(obj.num_channels, 1 , 1)
        title('Electrode Voltage (\muV)')
        end
        
        function update(obj,new_sensor_data)
            
            obj.sensor_data = [...
                obj.sensor_data(:,size(new_sensor_data,2) + 1:end) ...
                new_sensor_data(obj.channels,:)];
            
            for m = 1:obj.num_channels
                set(obj.line_handles(m),'Ydata',obj.sensor_data(m,:));
            end
            drawnow
        end
        
    end
    
end