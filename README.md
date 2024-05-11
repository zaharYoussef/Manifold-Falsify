# DomainSweep

This repository is a an extension of FalsifAI. In this work we are using a different coverage criteria to drive the falsification than the ones used in the FalsifAI work.

We are using a manifold coverage. The code used to train the vae and get the coverage can be found here: [https://github.umn.edu/zahar022/aahaa-testgen](https://github.umn.edu/zahar022/aahaa-testgen).

## System requirement


- Operating system: Linux or MacOS;

- Matlab (Simulink/Stateflow) version: >= 2020a. (Matlab license needed)

- Python version: >= 3.3

- MATLAB toolboxes dependency: 
  1. [Model Predictive Control Toolbox](https://www.mathworks.com/help/mpc/index.html) for ACC benchmark
  2. [Stateflow](https://www.mathworks.com/products/stateflow.html)
  3. [Deep Learning Toolbox](https://www.mathworks.com/products/deep-learning.html)
  4. [Deep Learning Toolbox Converter for TensorFlow Models] 

## Folder Structure Conventions

```
.
├── Makefile
├── README.md
├── benchmarks
│   ├── train
│   │   ├── ACC
│   │   │   ├── ACC_config.txt
│   │   │   ├── ACC_falsification.m
│   │   │   ├── ACC_falsify.m
│   │   │   └── ACC_trainController.m
│   ├── ACC
│   │   ├── dataset
│   │   │   └── ACC_trainset.mat
│   │   ├── model
│   │   │   ├── mpcACCsystem.slx
│   │   │   └── nncACCsystem.slx
│   │   ├── nnconfig
│   │   └── nncontroller
├── log/
├── results/
├── run
├── robustness_calculator.m(relied on Breach)
├── src
│   ├── TestGen.m
│   ├── cov
│   │   ├── comFiles
│   │   │   └── coverage_from_encoder.csv
│   │   │   └── data_flag.txt
│   │   │   └── data_to_encoder.csv
│   │   │   └── init_flag.txt
│   │   │   └── init_params.csv
│   │   └── GetManifoldCov.m
│   └── util
│       └── CQueue.m
└── test
│   ├── test.py
│   ├── scripts
│   └── config
│   │   ├── acc_3_30
│   │   ├── acc_4_30
│   │   ├── acc_5_30
│   │   ├── acc_3_50
│   │   ├── acc_4_50
│   │   └── acc_5_50
└── analyses
    ├── results.txt
    └── statTest.R

```

## Installation

- Clone the repository `git clone https://github.com/zaharYoussef/Manifold-Falsify.git`

- Install [Breach](https://github.com/decyphir/breach)
  1. start matlab, set up a C/C++ compiler using the command `mex -setup`. (Refer to [here](https://www.mathworks.com/help/matlab/matlabexternal/changing-default-compiler.html) for more details.)
  2. navigate to `breach/` in Matlab commandline, and run `InstallBreach`

 ## Usage

We have provided all the necessary code to reproduce our experiments but you need to have cloned and trained a VAE model using our repository mentioned above. If you are using a different code base for the VAE you just need to add code to read and write to our files in `src/cov/comFiles`. 

Once you have a traimed VAE you can follow these steps:
1. Set the appropriate paths to `Breach` and `DomainSweep` in the config files present in `test/config`.
2. Navigate to the directory `test/`. Run the command `python test.py config/[system config file]`.
3. Edit the permissions in `test/benchmarks/` to run the file using the following commandL `chmod -R 777 *`
4. Navigate to `src/cov/GetManifoldCov.m` and set the appropriate parameters to be able to run your vae encoder:<br/>
  exp_dir: path to the VAE directory<br/>
  dataset: name of dataset<br/>
  v: v value to be used in setting up coverage<br/>
  t: t value to be used in setting up T-Wise Combination coverage<br/>
  Keep in mind that *exp_dir* needs to be the relative path that works for the VAE codebase.
5. Set up the appropriate paths for the read and write files in `src\cov\comFile` in both codebases:
   1. DomainSweep
      Navigate to `src/cov/GetManifoldCov.m` and add the appropriate paths to all the files in `src\cov\comFile`
   2. VAE codebase
      Navigate to `vae/src/cov/matlabWrapper.py` and add the appropriate paths to all the files in `src\cov\comFile`.
6. Now the executable scripts have been generated under the directory `test/benchmarks/`. Users need to edit the executable scripts permission using the command `chmod -R 777 *`.
7. Navigate to the root directory `DomainSweep/` and run the command `make`. The automatically generated .csv experimental results will be stored in directory `results/`. The corresponding log will be stored under directory `output/`.
8. Run the `vae/src/cov/matlabWrapper.py` present in the VAE codebase.