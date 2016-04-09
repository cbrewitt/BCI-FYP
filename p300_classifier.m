classdef p300_classifier < handle
    % Can classify signals as P300.
    
    
    properties(Constant)
        PCA_VARIANCE = 85; % minimum percentage of total variance explained by PCA
        WINDOW_LENGTH = 0.7; % window length, windows are shortened to this
        NUM_DWT_COEFF = 8; % number of DWT coefficients to use
    end
    
    
    properties
        eeg;
        win_samples;
        trained;
        windows;
        targets;
        pca_coeff;
        num_pca;
        mean_target;
        mean_target_pca;
        best_dwt_coeffs;
        svm_model;
    end
    
    
    methods
        
        
        function obj = p300_classifier(eeg)
            % Constructor for the p300_classifier with eeg device
            % specified.
            
            obj.trained = false;
            obj.eeg = eeg;
            obj.win_samples = floor(obj.WINDOW_LENGTH*eeg.FS) + 1;
            obj.windows = zeros(0,eeg.NUM_CHANNELS,obj.win_samples);
            obj.targets = zeros(0,1);
        end
        
        
        function add_training_data(obj,windows,targets)
            % Add aditional training data. This does not train the classifier.
            %
            % 'windows' - 
            % An n x m x p matrix where n is the number of EEG
            % signal windows, m is the number of EEG channels and p is the
            % number of samples in each window.
            %
            % 'targets' -  
            % A logical vector of length n which specifys which
            % windows contain a P300 signal
            
            obj.windows = [obj.windows; windows(:,:,1:obj.win_samples)];
            obj.targets = logical([obj.targets; targets]);
            obj.trained = false;
        end
        
        
        function converged = train(obj)
            % Trains the SVM base on training data
            % 
            % 'converged' - Whether the SVM solver conveged or not
            
            % calculate the mean of all target windows
            obj.mean_target = squeeze(mean(obj.windows(obj.targets,:,:)));
            
            % calculate pca coefficients that explain 'PCA_VARIANCE'
            % percentage of total variance
            [obj.pca_coeff,~,~,~,explained] = pca(obj.mean_target');
            
            for n = 1:length(explained)
                if sum(explained(1:n)) > obj.PCA_VARIANCE
                    obj.num_pca = n;
                    obj.pca_coeff = obj.pca_coeff(:,1:n);
                    break
                end
            end
            
            % calculate pca of mean target signal
            obj.mean_target_pca = zeros(obj.num_pca,obj.win_samples);
            obj.mean_target_pca = obj.pca_coeff'*obj.mean_target;
            
            % pca of all target windows
            target_windows = obj.windows(obj.targets,:,:);
            num_targets = size(target_windows,1);
            target_windows_pca = zeros(num_targets, obj.num_pca, obj.win_samples);
            
            for n = 1:num_targets
                target_windows_pca(n,:,:) = obj.pca_coeff'*squeeze(target_windows(n,:,:));
            end
            
            % calculate the best wavelet coefficients
            obj.best_dwt_coeffs = zeros(obj.num_pca, obj.NUM_DWT_COEFF);
            
            for n = 1:obj.num_pca
                obj.best_dwt_coeffs(n,:) = Best_Coef(squeeze(target_windows_pca(:,n,:)),obj.NUM_DWT_COEFF);
            end
           
            predictor = obj.get_features(obj.windows);
            
            % train SVM
%              obj.svm_model = fitcsvm(predictor,obj.targets,'BoxConstraint',1,'Standardize',true);
%             
%             
%             converged = obj.svm_model.ConvergenceInfo.Converged;
%             obj.trained = converged;
%             
%             if(~converged)
%                 msgbox('Error: The SVM solver did not converge');
%             end
            
             %train LDA
             obj.svm_model = fitcdiscr(predictor,obj.targets); %LDA
             obj.trained = true;
        end
        
        
        function features = get_features(obj,windows)
            % Returns feature vectors for all windows.
            %
            % 'windows' - 
            % An n x m x p matrix where n is the number of EEG
            % signal windows, m is the number of EEG channels and p is the
            % number of samples in each window.
            %
            % 'features' - 
            % n x m matrix where n is the number of observations, and m is
            % the number of features
            
            windows = windows(:,:,1:obj.win_samples);
            
            % perform pca on all windows
            num_windows = size(windows,1);
            windows_pca = zeros(num_windows, obj.num_pca, obj.win_samples);
            
            for n = 1:num_windows
                windows_pca(n,:,:) = obj.pca_coeff'*squeeze(windows(n,:,:));
            end
            
            % correlation of signals with mean target signal
            mean_corr = zeros(num_windows,obj.num_pca);
            
            for n = 1:obj.num_pca
                for m = 1:num_windows
                    temp = corrcoef(obj.mean_target_pca(n,:)',squeeze(windows_pca(m,n,:))');
                    mean_corr(m,n) = temp(1,2);
                end
            end
            
            % wavelet coeffs
            dwt_coeff = zeros(num_windows,obj.num_pca,obj.NUM_DWT_COEFF);
            Power= zeros(num_windows,obj.num_pca, 2);
            Sig_entropy=zeros(num_windows,obj.num_pca, 1);
            NLE=zeros(num_windows,obj.num_pca, 2);

            for n = 1:obj.num_pca
                [dwt_coeff(:,n,:), Power(:,n,:),Sig_entropy(:,n,:),NLE(:,n,:)] = Wavelet_Feat(squeeze(windows_pca(:,n,:)),obj.best_dwt_coeffs(n,:));
            end
            
            % feature vector
            features = [mean_corr reshape(dwt_coeff,num_windows,[]),reshape(Sig_entropy,num_windows,[]), reshape(NLE,num_windows,[])];
        end
        %reshape(Cfs_entropy,num_windows,[])
        %reshape(Power,num_windows,[])
        function [label,score] = classify(obj,windows)
            % Classifies EEG signals as P300 or non-P300.
            %
            % 'windows' - 
            % An n x m x p matrix where n is the number of EEG
            % signal windows, m is the number of EEG channels and p is the
            % number of samples in each window.
            %
            % 'label' - 
            % Logical vector showing the classification of each window
            %
            % 'score' - 
            % Numerical score coresponding to how likely each window is to
            % contain P300.
            
            predictor = obj.get_features(windows);
            [label,score] = predict(obj.svm_model, predictor);
            
        end
        

    end
    
 

end