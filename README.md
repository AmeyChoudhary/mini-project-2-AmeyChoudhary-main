[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/DLipn7os)
# Intro to Xv6
OSN Monsoon 2023 mini project 2

## Some pointers
- main xv6 source code is present inside `initial_xv6/src` directory. This is where you will be making all the additions/modifications necessary for the first 3 specifications. 
- work inside the `networks/` directory for the Specification 4 as mentioned in the assignment.
- Instructions to test the xv6 implementations are given in the `initial_xv6/README.md` file. 

- You are free to delete these instructions and add your report before submitting. 

## My README

### Disclaimer 

I have used ChatGPT and Copilot, for assistance in the mini project.

### Specification 1

#### System Call 1 (getreadcount())
- I have implemented getreadcount() as directed. To test it, follow the directions given in README.md in initial_xv6 directory.
- The system call passes the first test as expected.

#### System Call 2 (sigalarm() and sigreturn())
- I have implemented sigalarm() and sigreturn() as directed. To test it, follow the directions given in README.md in initial_xv6 directory. Run

```
alarmtest
```
   in xv6. 
- The system call passes.

### Specification 2 (Scheduling)

- I have implemented the `FCFS` and `MLFQ` as asked. I have also made changes to the `Makefile` to include flags for scheduler.

- Command to run a particular scheduler in initial_xv6/src directory:
```
prompt> make clean qemu SCHEDULER=<scheduler_name> CPUS=<CPU_number>
```
In case any flag is missing, the default is `Round Robin` and `3` CPUs


### Specification 3 (Report for xv6 scheduler)

- Given in the folder `Reports`, in `XV6_Scheduler_Report.pdf`

### Specification 4 (Networks)
Given in networks/README.md

### Usertests are also passing.