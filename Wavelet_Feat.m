
function [Feat_Wavelet ,Feat_band_power,Sig_Entropy,Non_Linear_Energy]= Wavelet_Feat(single_wins,Index)
%single_wins=target_wins;
NUM_WINS=size(single_wins,1);
Cfs=zeros(NUM_WINS,34);
Mean_EB1=zeros(NUM_WINS,1);
Mean_EB2=zeros(NUM_WINS,1);
NLE1=zeros(NUM_WINS,1);
NLE2=zeros(NUM_WINS,1);
Ent_sig=zeros(NUM_WINS,1);
Xsig = single_wins  - repmat(mean(single_wins,2),1,size(single_wins,2));% DC offset removal
for n=1:NUM_WINS
 %          Signal Entropy     
   Entropy=wentropy((Xsig(n,:)),'shannon');
   Ent_sig(n,:)=Entropy;
  
   
   %Wavelet Decomposition
   Tar_wpt =wpdec(Xsig(n,:),5,'db8'); %wavelet level 3 decopmposition
   %&&&&&&       0-2Hz  &&&&&&&
   cfs1= wpcoef(Tar_wpt,[5 0]);
   % Band Energy
   
   for i=1:length(cfs1);
       k=2:(length(cfs1)-1);
       EB1=((cfs1(i)).^2);
       % Non Linear Energy
       LE1= (1/(length(cfs1)-2))*sum(((cfs1(k)).^2)-(cfs1(k-1)).*(cfs1(k+1)));
   end 
  Mean_EB1(n,:)=mean(EB1);
  NLE1(n,:)=LE1;
   
  %&&&&&&       2-4Hz  &&&&&&&
  cfs2= wpcoef(Tar_wpt,[5 1]);
  for j=1:length(cfs2);
      k2=2:(length(cfs2)-1);
       EB2=((cfs2(j)).^2);
     % Non Linear Energy
       LE2= (1/(length(cfs2)-2))*sum(((cfs2(k2)).^2)-(cfs2(k2-1)).*(cfs2(k2+1)));
  end 
  Mean_EB2(n,:)=mean(EB2);
  NLE2(n,:)=LE2;


  %         4-8Hz
  %cfs3= wpcoef(Tar_wpt,[4 1]);
  
  Cfs(n,:)=[cfs1 cfs2];
end 
Non_Linear_Energy=[NLE1 NLE2];
Sig_Entropy=Ent_sig;
Feat_band_power=[Mean_EB1 Mean_EB2];
Feat_Wavelet = Cfs(:,Index);
