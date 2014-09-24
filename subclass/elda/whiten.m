% function [R,neg] = whiten(bg,nx,ny)
% Obtain whitenixng matrix and mean from a general HOG model   
% by a cholesky decompoition on a stationairy covariance matrix 
% feat' = R\(feat - neg) has zero mean and unit covariance
%
% bg.neg: negative mean (nf by 1)
% bg.cov: covariance for k spatial offsets (nf by nf by k)
% bg.dxy: k spatial offsets (k by 2)
% bg.lambda: regularizer
function [R,neg] = whiten(bg,nx,ny)
  neg = repmat(bg.neg',ny*nx,1);
  neg = neg(:);
  p=1;
  while(p~=0)
  sig = reconstructSig(nx,ny,bg.cov,bg.dxy);
  sig = sig + bg.lambda*eye(size(sig));
  [R,p] = chol(sig);
  if p ~= 0,
	disp('Increasing lambda');
	bg.lambda=bg.lambda+0.01;
    %display('Sig is not positive definite, add a larger regularizer');
    %keyboard;
  end
  end
  
function w = reconstructSig(nx,ny,ww,dxy)
% W = reconstructSig(nx,ny,ww,dxy)
% W = n x n 
% n = ny * nx * nf

  k  = size(dxy,1);
  nf = size(ww,1);
  n  = ny*nx;  
  w  = zeros(nf,nf,n,n);
  
  for x1 = 1:nx,
    for y1 = 1:ny,
      i1 = (x1-1)*ny + y1;
      for i = 1:k,
        x = dxy(i,1);
        y = dxy(i,2);
        x2 = x1 + x;        
        y2 = y1 + y;
        if x2 >= 1 && x2 <= nx && y2 >= 1 && y2 <= ny,
          i2 = (x2-1)*ny + y2;
          w(:,:,i1,i2) = ww(:,:,i); 
        end
        x2 = x1 - x;        
        y2 = y1 - y;
        if x2 >= 1 && x2 <= nx && y2 >= 1 && y2 <= ny,
          i2 = (x2-1)*ny + y2; 
          w(:,:,i1,i2) = ww(:,:,i)'; 
        end
      end
    end
  end
  
  % Permute [nf nf n n] to [n nf n nf]
  w = permute(w,[3 1 4 2]);
  w = reshape(w,n*nf,n*nf);
  
  % Make sure returned matrix is close to symmetric
  assert(sum(sum(abs(w - w'))) < 1e-5);
  
  w = (w+w')/2;
