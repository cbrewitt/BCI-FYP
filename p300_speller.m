classdef p300_speller < handle
   
    properties(Constant)
        eeg = emotiv_epoc;
        WINDOW_LENGTH = 1;
        WINDOW_SAMPLES = floor(p300_speller.eeg.FS*p300_speller.WINDOW_LENGTH);
        NUM_ROWS = 6;
        NUM_COLUMNS = 6;
        ROWS_AND_COLS = p300_speller.NUM_COLUMNS + p300_speller.NUM_ROWS;
        SPELLING_BUFFER_SIZE = 20;
        DELAY_BETWEEN_CHARACHTERS = 3;

    end
    
    properties
        classifier;
        username;
        handles;
        grid_handles;
        cancelled = false;
        training_words = {'among','bring','shape','plane','force', ...
                          'world','build','group','night','point', ...
                          'study','house','power','entry','right', ...
                          'money','water','pause','brain','topic'};
        grid_charachters = ['A','B','C','D','E','F';
                            'G','H','I','J','K','L';
                            'M','N','O','P','Q','R';
                            'S','T','U','V','W','X';
                            'Y','Z','1','2','3','4';
                            '5','6','7','8','_','<'];
        num_training_words = 3;
        num_reps = 10;
        flash_col = [1,1,1];
        grey_col = [0.3,0.3,0.3];
        flash_freq = 6;
        small_char_size = 48;
        big_char_size = 64;
        realtime_plot;
    end
    
    methods
        
        %getters
        function val = window_interval(obj)
            val = floor((1/obj.flash_freq)*obj.eeg.FS)/obj.eeg.FS;
        end
        
        function val = interval_samples(obj)
            val = floor(obj.window_interval*obj.eeg.FS);
        end
        
        function val = total_time(obj)
            val = (obj.NUM_COLUMNS + obj.NUM_ROWS)*obj.num_reps*obj.window_interval + obj.WINDOW_LENGTH;
        end
        
        %methods
        function obj = p300_speller(gui_handles)
            % Constructor for P300 speller
            
            obj.handles = gui_handles;
            obj.grid_handles = [obj.handles.grid11, obj.handles.grid12, obj.handles.grid13, obj.handles.grid14, obj.handles.grid15, obj.handles.grid16;
                                obj.handles.grid21, obj.handles.grid22, obj.handles.grid23, obj.handles.grid24, obj.handles.grid25, obj.handles.grid26;
                                obj.handles.grid31, obj.handles.grid32, obj.handles.grid33, obj.handles.grid34, obj.handles.grid35, obj.handles.grid36;
                                obj.handles.grid41, obj.handles.grid42, obj.handles.grid43, obj.handles.grid44, obj.handles.grid45, obj.handles.grid46;
                                obj.handles.grid51, obj.handles.grid52, obj.handles.grid53, obj.handles.grid54, obj.handles.grid55, obj.handles.grid56;
                                obj.handles.grid61, obj.handles.grid62, obj.handles.grid63, obj.handles.grid64, obj.handles.grid65, obj.handles.grid66];
                            
            % set all charachters in grid
            for n = 1:size(obj.grid_handles,1)
                for m = 1:size(obj.grid_handles,2)

                    if ~(m==6 && n==6)
                        set(obj.grid_handles(m,n), 'String', obj.grid_charachters(m,n));
                    end
                    set(obj.grid_handles(n,m),'ForegroundColor',obj.grey_col);
                end
            end
            
            obj.classifier = p300_classifier(obj.eeg);
            obj.realtime_plot = eeg_realtime_plot;
            
        end
        
        
        function train(obj)
            % collects training data and trans the SVM
            
            obj.cancelled = false;
            target_wins = zeros(0,obj.eeg.NUM_CHANNELS,obj.WINDOW_SAMPLES);
            non_target_wins = zeros(0,obj.eeg.NUM_CHANNELS,obj.WINDOW_SAMPLES);
            target_words_I = randperm(length(obj.training_words));
            
            for p = 1:obj.num_training_words
                
                target_word = upper(obj.training_words{target_words_I(p)});
                num_windows = obj.ROWS_AND_COLS*obj.num_reps*length(target_word);
                
                obj.handles.targetwordtext.String = target_word;
                
                % raw eeg windows, no averaging done
                raw.windows = zeros(num_windows,obj.eeg.NUM_CHANNELS,obj.WINDOW_SAMPLES);
                raw.flash = zeros(num_windows,1);
                raw.target_row = zeros(num_windows,1);
                raw.target_col = zeros(num_windows,1);

                for n = 1:length(target_word)
                    target_char = upper(target_word(n));
                    set(obj.handles.targetchartext,'String',target_char);

                    [target_row,target_col] = find(obj.grid_charachters == target_char);

                    if isempty(target_row)
                        error('Invalid target charachter')
                    end
 
                    if(obj.cancelled)
                        return
                    end
                    
                    sound(sin(1:1024),4096);
                    set(obj.grid_handles(target_row,target_col),'ForegroundColor',[1,0,0]);
                    pause(2);
                    set(obj.grid_handles(target_row,target_col),'ForegroundColor',obj.grey_col);
                    
                    [row_wins, col_wins] = obj.aquire();
                    
                    if(obj.cancelled)
                        return
                    end
                    
                    
                    
                    % store data
                    all_wins = [row_wins; col_wins];

                    for m = 1:obj.ROWS_AND_COLS;
                        I = ((n-1)*obj.ROWS_AND_COLS + (m-1))*obj.num_reps + (1:obj.num_reps);
                        raw.windows(I,:,:) = squeeze(all_wins(m,:,:,:));
                        raw.flash(I) = m;
                    end
                    I = (n-1)*obj.ROWS_AND_COLS*obj.num_reps + (1:obj.ROWS_AND_COLS*obj.num_reps);
                    raw.target_row(I) = target_row;
                    raw.target_col(I) = target_col;

                    % remove artifacts and get mean 
                    artifact_threshold = 50; % uV all windows with voltage above this are discarded
                    mean_row_wins = zeros(size(row_wins,1),size(row_wins,3),size(row_wins,4));
                    mean_col_wins = zeros(size(col_wins,1),size(col_wins,3),size(col_wins,4));
                    
                    %row_wins = zeros(obj.NUM_ROWS, obj.num_reps, obj.eeg.NUM_CHANNELS, obj.WINDOW_SAMPLES);
                    %column_wins = zeros(obj.NUM_COLUMNS, obj.num_reps, obj.eeg.NUM_CHANNELS, obj.WINDOW_SAMPLES);

                    %I = max(max(abs(row_wins),[],3),[],4) < artifact_threshold;
                    
                    I = max(abs(row_wins),[],4) < artifact_threshold;

                    for m = 1:size(row_wins,1)
                        for q = 1:size(row_wins,3)
                            %mean_row_wins(m,:,:) = squeeze(mean(row_wins(m,I(m,:),:,:),2));
                            mean_row_wins(m,q,:) = squeeze(mean(row_wins(m,squeeze(I(m,:,q)),q,:),2));
                        end
                    end

                    I = max(abs(col_wins),[],4) < artifact_threshold;
    
                    for m = 1:size(col_wins,1)
                        for q = 1:size(col_wins,3)
                            mean_col_wins(m,q,:) = squeeze(mean(col_wins(m,squeeze(I(m,:,q)),q,:),2));
                        end
                    end
                    
                    target_wins = cat(1,target_wins,cat(1,mean_row_wins(target_row,:,:),mean_col_wins(target_col,:,:)));    
                    non_target_wins = cat(1,non_target_wins,cat(1,mean_row_wins((1:size(row_wins,1))~=target_row,:,:),mean_col_wins((1:size(col_wins,1))~=target_col,:,:)));
                end
                sound(sin(1:1024),4096); %beep


                user_name = get(obj.handles.usernametext,'String');
                if ~isempty(user_name)
                    current_target_wins = target_wins(end+1-length(target_word)*2:end,:,:,:);
                    current_non_target_wins = non_target_wins(end+1-length(target_word)*10:end,:,:,:);
                    p300_data = struct('target_wins',current_target_wins,'non_target_wins',current_non_target_wins,'target_word',target_word,'user_name',user_name,'raw',raw);
                    filename = strrep(strrep(strrep(['P300_Data\' user_name '\P300_data_' datestr(datetime('now'))],' ','_'),':','_'),'-','_');
                    try
                        mkdir(['P300_Data\' user_name ]);
                        save(filename, 'p300_data');
                    catch ME
                        disp(ME);
                    end
                end
            end
            
            windows = [target_wins;non_target_wins];
            targets = [true(1,size(target_wins,1)) false(1,size(non_target_wins,1))]';
            
            % add data to classifier and train
            obj.classifier.add_training_data(windows,targets);
            
            obj.handles.trainingmessage.Visible = 'on';
            drawnow
            obj.classifier.train();
            obj.handles.trainingmessage.Visible = 'off';
            drawnow
            
            
        end
        
        
        function [row_wins, column_wins] = aquire(obj)
            windows_received = 0;

            % filtered EEG data
            sensor_data = zeros(14, obj.total_time*obj.eeg.FS);

            % Create order of flashes randomly. Each row/column should repeat at least once
            % every 12 flashes, no row or column will flash twice in a row.
            flash_order = generate_flash_order();

            % aquire data
            callback = @(x) data_received(x);
            obj.eeg.aquire(obj.total_time, callback, obj.window_interval);


            % sort data into windows
            [row_wins,column_wins] = sort_row_col(sensor_data);


            % callback function when data is received
            function data_received(sensor_data_in)
                windows_received = windows_received + 1;

                % flash the row/column
                if windows_received <= length(flash_order)
                    index = flash_order(windows_received);
                    row =  index <= obj.NUM_ROWS;

                    if ~row
                        index = index - obj.NUM_ROWS;
                    end

                    duration = 0.6*obj.window_interval;
                    flash_rowcol(index,row,duration,sensor_data_in);
                end
                
                
                %record data
                sensor_data(:,(windows_received-1)*obj.interval_samples + (1:obj.interval_samples)) = sensor_data_in;
            end


            % flash row/column
            function flash_rowcol(index,row,duration,sensor_data_in)   
                
                if row
                    m = index;
                    n = 1:6;
                else
                    m = 1:6;
                    n = index;
                end

                for x = m
                    for y = n
                        set(obj.grid_handles(m,n),'ForegroundColor',obj.flash_col);
                        set(obj.grid_handles(m,n),'FontSize',obj.big_char_size);
                    end
                end
                drawnow
                
                tic;
                
                %update plot
                obj.realtime_plot.update(sensor_data_in);
                update_duration = toc;
                
                if update_duration < duration
                    pause(duration - update_duration);
                end
                
                for x = m
                    for y = n
                        set(obj.grid_handles(m,n),'ForegroundColor',obj.grey_col);
                        set(obj.grid_handles(m,n),'FontSize',obj.small_char_size);
                    end
                end
                drawnow
            end

            
            function flash_order = generate_flash_order()
                flash_order = zeros(1,obj.ROWS_AND_COLS*obj.num_reps);
                flash_order(1:obj.ROWS_AND_COLS)= randperm(obj.ROWS_AND_COLS);
                min_gap = 2;
                non_min_gap = obj.ROWS_AND_COLS - min_gap;

                for n = 2:obj.num_reps
                    series = flash_order((n-2)*obj.ROWS_AND_COLS + (1:obj.ROWS_AND_COLS)); %copy last series
                    series(1:non_min_gap) = series(randperm(non_min_gap)); % shuffle all except last few
                    series(min_gap + (1:non_min_gap)) = series(min_gap + randperm(non_min_gap)); % shuffle all except first few
                    flash_order((n-1)*obj.ROWS_AND_COLS + (1:obj.ROWS_AND_COLS)) = series;
                end
            end

            
            function [row_wins,column_wins] = sort_row_col(sensor_data)

                row_wins = zeros(obj.NUM_ROWS, obj.num_reps, obj.eeg.NUM_CHANNELS, obj.WINDOW_SAMPLES);
                column_wins = zeros(obj.NUM_COLUMNS, obj.num_reps, obj.eeg.NUM_CHANNELS, obj.WINDOW_SAMPLES);

                for n = 1:obj.NUM_ROWS
                    I = find(flash_order == n);
                    start_I = I.*obj.interval_samples+1;
                    for m = 1:obj.num_reps;
                        row_wins(n,m,:,:) = sensor_data(:,start_I(m):(start_I(m)+obj.WINDOW_SAMPLES-1));
                    end
                end

                for n = obj.NUM_ROWS + (1:obj.NUM_COLUMNS)
                    I = find(flash_order == n);
                    start_I = I.*obj.interval_samples+1;
                    for m = 1:obj.num_reps;
                        column_wins(n-obj.NUM_ROWS,m,:,:) = sensor_data(:,start_I(m):(start_I(m)+obj.WINDOW_SAMPLES-1));
                    end
                end
            end

        end
        
        
        function spell(obj)


            obj.cancelled = false;
            obj.handles.spellingtext.String = '';       
            
            while(~obj.cancelled)
                
                % beep
                sound(sin(1:1024),4096);
                pause(obj.DELAY_BETWEEN_CHARACHTERS);
                
                % aquire data for one charachter
                [row_wins, col_wins] = obj.aquire();
                tic
                
                % check if cancelled
                if(obj.cancelled)
                        return
                end
                
                % determine target charachter
                [~,score] = obj.classifier.classify(squeeze(mean(row_wins,2)));
                [~,target_row] = max(score(:,2));
                
                [~,score] = obj.classifier.classify(squeeze(mean(col_wins,2)));
                [~,target_col] = max(score(:,2));
                
                target_char = obj.grid_charachters(target_row,target_col);
                
                % check for space
                if target_char == '_'
                    target_char = ' ';
                end
                
                current_string = obj.handles.spellingtext.String;
                
                % check for backspace
                if target_char == '<' && ~isempty(current_string)
                    obj.handles.spellingtext.String = current_string(1:end-1);
                    
                % add new charachter
                elseif length(current_string) < obj.SPELLING_BUFFER_SIZE;
                    obj.handles.spellingtext.String = [current_string target_char];
                else
                    obj.handles.spellingtext.String = [current_string(2:end) target_char];
                end
                      
            end
        end
        
        
    end
end