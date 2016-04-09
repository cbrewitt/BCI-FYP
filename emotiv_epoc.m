classdef emotiv_epoc < handle
   
    properties(Constant)
        NUM_CHANNELS = 14;
        CHANNEL_NAMES = ['F3 ';'FC5';'AF3';'F7 ';'T7 ';'P7 ';'O1 ';'O2 ';'P8 ';'T8 ';'F8 ';'AF4';'FC6';'F4 '];
        FS = 128;
        LSB_VAL = 0.51; %uV
    end
    
    properties
        cancelled = false;
        dummy_input = false;
    end
    
    methods
        function aquire(obj,runtime,callback,callback_interval)
            obj.cancelled = false;
            runtime = floor(runtime*obj.FS)/obj.FS;
            
            if(obj.dummy_input)
                num_windows = runtime/callback_interval;
                window_samples = callback_interval*obj.FS;

                callback_duration = callback_interval;

                for n = 1:num_windows
                    if obj.cancelled
                        return
                    end
                    
                    pause(callback_interval - callback_duration)
                    sensor_data = wgn(obj.NUM_CHANNELS,window_samples,0);
                    tic
                    callback(sensor_data);
                    callback_duration = toc;
                end
            else

                % filtering
                fc = 15;
                Wn = 2*fc/obj.FS;
                lp_ord = 2;
                [lp_num, lp_den] = butter(lp_ord,Wn,'low');
                lp_in = zeros(obj.NUM_CHANNELS,length(lp_num));
                lp_out = zeros(obj.NUM_CHANNELS,length(lp_den));

                fc = 0.5;
                Wn = 2*fc/obj.FS;
                hp_ord = 2;
                [hp_num, hp_den] = butter(hp_ord,Wn,'high');
                hp_in = zeros(obj.NUM_CHANNELS,length(hp_num));
                hp_out = zeros(obj.NUM_CHANNELS,length(hp_den));

                % data
                callback_interval_samples = floor(callback_interval*obj.FS);
                sensor_data = zeros(obj.NUM_CHANNELS,callback_interval_samples);
                sensor_data_filt = sensor_data;


                % open connection to python script
                headset_tcp=tcpip('127.0.0.1',7462, 'NetworkRole', 'client', 'ByteOrder', 'littleEndian');

                if obj.cancelled
                    return
                end
                
                tries = 5;
                for n = 1:tries
                    try
                        system('Taskkill /f /im python.exe');
                    catch ME
                        disp();
                        if strcmp(ME.identifier, 'ERROR: The process "python.exe" not found.')
                            disp(ME);
                        else
                            rethrow(ME);
                        end
                    end
                    system('START /B python bci_aquisition.py');
                    pause(tries);
                    
                    if obj.cancelled
                        return
                    end
                    
                    try
                        fopen(headset_tcp);          
                        break;
                    catch ME
                        disp(ME);
                        if n == tries
                            rethrow(ME);
                        end
                    end
                end
                flushinput(headset_tcp);

                % read one sample to estimate dc ofobj.FSet
                dc_offset = obj.LSB_VAL*fread(headset_tcp, obj.NUM_CHANNELS, 'int16');
                samples_read = 0;
                while((runtime == 0 || samples_read < runtime*obj.FS) && ~obj.cancelled)

                    %previous_sensor_data = sensor_data;

                    for n = 1:callback_interval_samples
                        % read data from sensor through tcp/ip socket
                        sensor_data(:,n) = obj.LSB_VAL*fread(headset_tcp, obj.NUM_CHANNELS, 'int16') - dc_offset; 

                        lp_in = [sensor_data(:,n) lp_in(:,1:(end-1))];

                        for m = 1:obj.NUM_CHANNELS
                            lp_out(m,:) = [1/lp_den(1).*(sum(lp_num.*lp_in(m,:))-sum(lp_den(2:end).*lp_out(m,1:(end-1)))) lp_out(m,1:(end-1))];         
                            hp_in(m,:) = [lp_out(m,1) hp_in(m,1:(end-1))];
                            hp_out(m,:) = [1/hp_den(1).*(sum(hp_num.*hp_in(m,:))-sum(hp_den(2:end).*hp_out(m,1:(end-1)))) hp_out(m,1:(end-1))];
                        end

                        sensor_data_filt(:,n) = hp_out(:,1);

                    end
                    flushinput(headset_tcp);

                    callback(sensor_data_filt);

                    samples_read = samples_read + callback_interval_samples;

                end
                fclose(headset_tcp);
            end
        end
    end
end