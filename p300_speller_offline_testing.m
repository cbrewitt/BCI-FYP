%% load data
K1=5;
Correct=zeros(K1,2);
for k=1:K1

k
[target_wins,non_target_wins] = load_training_data('Ian_train9');

windows = [target_wins;non_target_wins];
targets = [true(1,size(target_wins,1)) false(1,size(non_target_wins,1))]';

%% train classifier

% choose training and testing data
[train, test] = crossvalind('holdOut',targets,1/3);

classifier = p300_classifier(emotiv_epoc);
classifier.add_training_data(windows(train,:,:),targets(train));
classifier.train();

%% test how good SVM is at predicting letter
[label,score] = classifier.classify(windows(test,:,:));

target_scores = score(targets(test),2);
non_target_scores = score(~targets(test),2);

success_char = 0;
num_trials = 1000;
for n = 1:num_trials
   rand_target_score = target_scores(randi(length(target_scores)));
   rand_non_target_scores = non_target_scores(randperm(length(non_target_scores)));
   if rand_target_score > rand_non_target_scores(1:5)
       success_char = success_char + 1;
   end
end

cp = classperf(targets);
classperf(cp,label,test);

correct_class = cp.CorrectRate;
correct_row_col = success_char/num_trials;
correct_charachter = (success_char/num_trials).^2;
charachter_rate = 2*correct_charachter-1;

Correct(k,:)=[correct_class correct_row_col] ;
end
A=mean(Correct);
Ast=std(Correct);
Correct_letter=[A(2).^2 2.*A(2).*Ast(2)./(sqrt(K1))]
Rate=2*Correct_letter(1)-1




%