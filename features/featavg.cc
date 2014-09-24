#include <math.h>
#include "mex.h"

// small value, used to avoid division by zero
#define eps 0.0001

static inline float min(float x, float y) { return (x <= y ? x : y); }
static inline float max(float x, float y) { return (x <= y ? y : x); }

static inline int min(int x, int y) { return (x <= y ? x : y); }
static inline int max(int x, int y) { return (x <= y ? y : x); }

// main function:
// takes a double color image and a bin size 
// returns HOG features
mxArray *process(const mxArray *mximage, const mxArray *mxsbin) {
  double *im = (double *)mxGetPr(mximage);
  const int *dims = mxGetDimensions(mximage);
  if (mxGetNumberOfDimensions(mximage) != 3 ||
      mxGetClassID(mximage) != mxDOUBLE_CLASS)
    mexErrMsgTxt("Invalid input");

  int sbin = (int)mxGetScalar(mxsbin);
  // int dim2 = dims[2];

  // memory for caching orientation histograms & their norms
  int blocks[2];
  blocks[0] = (int)round((double)dims[0]/(double)sbin);
  blocks[1] = (int)round((double)dims[1]/(double)sbin);
  double *hist = (double *)mxCalloc(blocks[0]*blocks[1]*dims[2], sizeof(double));
  double *norm = (double *)mxCalloc(blocks[0]*blocks[1]*dims[2], sizeof(double));

  // memory for Blocked features
  int out[3];
  out[0] = max(blocks[0]-2, 0);
  out[1] = max(blocks[1]-2, 0);
  out[2] = dims[2];
  mxArray *mxfeat = mxCreateNumericArray(3, out, mxSINGLE_CLASS, mxREAL);
  float *feat = (float *)mxGetPr(mxfeat);
  
  int visible[2];
  visible[0] = blocks[0]*sbin;
  visible[1] = blocks[1]*sbin;
  
  for (int z = 0; z < dims[2]; z++) {
    for (int x = 1; x < visible[1]-1; x++) {
      for (int y = 1; y < visible[0]-1; y++) {
        // select the value
        double *s = im + min(x, dims[1]-2)*dims[0] + min(y, dims[0]-2) + z*dims[0]*dims[1];
        double v = *s;
        // mexPrintf("%6f\n",v);
      
        // add to 4 blocks around pixel using linear interpolation
        double xp = ((double)x+0.5)/(double)sbin - 0.5;
        double yp = ((double)y+0.5)/(double)sbin - 0.5;
        int ixp = (int)floor(xp);
        int iyp = (int)floor(yp);
        double vx0 = xp-ixp;
        double vy0 = yp-iyp;
        double vx1 = 1.0-vx0;
        double vy1 = 1.0-vy0;
        // v = sqrt(v);

        if (ixp >= 0 && iyp >= 0) {
          *(hist + ixp*blocks[0] + iyp + z*blocks[0]*blocks[1]) += 
            vx1*vy1*v;
          *(norm + ixp*blocks[0] + iyp + z*blocks[0]*blocks[1]) += 
            vx1*vy1;
        }

        if (ixp+1 < blocks[1] && iyp >= 0) {
          *(hist + (ixp+1)*blocks[0] + iyp + z*blocks[0]*blocks[1]) += 
            vx0*vy1*v;
          *(norm + (ixp+1)*blocks[0] + iyp + z*blocks[0]*blocks[1]) += 
            vx0*vy1;
        }

        if (ixp >= 0 && iyp+1 < blocks[0]) {
          *(hist + ixp*blocks[0] + (iyp+1) + z*blocks[0]*blocks[1]) += 
            vx1*vy0*v;
          *(norm + ixp*blocks[0] + (iyp+1) + z*blocks[0]*blocks[1]) += 
            vx1*vy0;
        }

        if (ixp+1 < blocks[1] && iyp+1 < blocks[0]) {
          *(hist + (ixp+1)*blocks[0] + (iyp+1) + z*blocks[0]*blocks[1]) += 
            vx0*vy0*v;
          *(norm + (ixp+1)*blocks[0] + (iyp+1) + z*blocks[0]*blocks[1]) += 
            vx0*vy0;
        }
      }
    }
  }

  // compute features
  for (int z = 0; z < dims[2]; z++) {
    for (int x = 0; x < out[1]; x++) {
      for (int y = 0; y < out[0]; y++) {
        float *dst = feat + x*out[0] + y + z*out[0]*out[1];
        double *s = hist + (x+1)*blocks[0] + y+1 + z*blocks[0]*blocks[1];
        double *p = norm + (x+1)*blocks[0] + y+1 + z*blocks[0]*blocks[1];
        *dst = (float) (*s / (*p + eps));
      }
    }
  }

  mxFree(hist);
  mxFree(norm);
  return mxfeat;
}

// matlab entry point
// F = features(image, bin)
// image should be color with double values
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  if (nrhs != 2)
    mexErrMsgTxt("Wrong number of inputs"); 
  if (nlhs != 1)
    mexErrMsgTxt("Wrong number of outputs");
  plhs[0] = process(prhs[0], prhs[1]);
}



