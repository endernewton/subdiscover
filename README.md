This code base is mainly for the paper:

Xinlei Chen, Abhinav Shrivastava, and Abhinav Gupta. 
"Enriching Visual Knowledge Bases via Object Discovery and Segmentation." CVPR, 2014.

However, by ignoring the segmentation part, you can also use it to clean up web data, which is proposed in:

Xinlei Chen, Abhinav Shrivastava, and Abhinav Gupta. 
"NEIL: Extracting Visual Knowledge from Web Data." ICCV, 2013.

Usage:

0. Set up the path to your data in startup.m, mainly data path and cache path, the code will loop over all the datasets in the data folder create files in the cache folder;
1. If you do not have ground truth, that's fine, just leave it and do not evaluate the results;
2. See Pipeline.m for the order of functions to call;
4. In general this code is suitable for computing clusters, though you can run small-scale experiments on a single machine.
5. I have only tested it on Linux, but please do let me know if you get it working on Windows machines.

I made major modifications after the paper got published:

0. Initial seeds for ELDA training are produced by cropping each image using the edge map produced by Structured Edge Detection Toolbox;
1. For subcategory discovery, instead of spectral clustering, this code simply merges the initial clusters (formed by ELDA top detections), it works pretty well and runs much faster;
2. The default option is HOG instead of Colored HOG, the performance does not change that much;
3. Can fix the random seed. The original experiments for CVPR 2014 were done on a computing cluster where each node had its own random seeds. This makes the results not reproducable. Now it is fixed.

For negative data to train Latent SVMs, in principle you can use any data you want, but I have provided the negative dataset we used at my project page (http://www.cs.cmu.edu/~xinleic/seg.html).

For reference, the new results (if you fix the random seed) are

The Internet Dataset (Rubinstein CVPR 2013)
>Airplane: P 0.9219 J 0.6087
>Car: P 0.8728 J 0.6274
>Horse: P 0.9011 J 0.6023

100 Samples from The Internet Dataset
>Airplane: P 0.8992 J 0.5462
>Car: P 0.8937 J 0.6920
>Horse: P 0.8805 J 0.4446

Credit goes to:
 
0. Bharath Hariharan et al for Exemplar LDA code; 
1. Olga Veksler for Graph Cut and Max Flow code; 
2. Piotr Dollar and Larry Zitnick for Structured Edge Detection Toolbox; 
3. Deformable Part Model version 5; 
4. Alexander Vezhnevets et al for code that transfers masks for figure ground segmentation; 
5. Miki Rubinstein et al for the datasets and evaluation codes.

If you find anything (like a bug or missing credit or failure to reproduce the results), feel free to contact me (enderchen@cs.cmu.edu).

Xinlei Chen, CMU
