# Development of an automatic tool for periodic surveillance of actuarial and demographic indicators

Repository for my final master project at UC3M titled "Development of an automatic tool for periodic surveillance of actuarial and demographic indicators"

## My tutors for the project:

- [María Luz Durbán Reguera](https://researchportal.uc3m.es/display/inv18373)
- [Bernardo D'Auria](https://portal.uc3m.es/portal/page/portal/dpto_estadistica/home/members/bernardo_d_auria)

## How to run:

Temporarily, a way you can run this is by running the following lines in your R console:

> library(shiny)
> runGitHub(repo='tfm_uc3m', username='dreth', ref='main', subdir='dashboard')

Optionally, if R is not in your PATH (R does this automatically during install), you could add the following line to your .bashrc or .bash_profile file:

> export PATH="$PATH:**PATH TO R BINARY**"

In the bold part, just replace with the location of your R binary.