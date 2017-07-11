# DCS Bash Application for Sentinel-2 Atmospheric Correction

This processing services applies the SEN2COR atmospheric correction to Sentinel-2 Level 1C tiles. The inputs are thus Sentinel-2 products containing Top of Atmosphere reflectances (TOA) and the outputs are Sentinel-2 products containing the tiles covering the area of interest and containing Bottom of Atmosphere reflectances (BOA).

SEN2COR is a prototype processor for Sentinel-2 Level 2A product formatting and processing. The processor performs the tasks of atmospheric, terrain and cirrus correction and a scene classification of Level 1C input data.

Sentinel-2 Level 2A outputs are:

* Bottom-Of-Atmosphere (BOA), optionally terrain and cirrus corrected reflectance images
* Aerosol Optical Thickness
* Water Vapour
* Scene Classification maps and Quality Indicators, including cloud and snow probabilities.

## Quick links
 
* [Getting Started](#getting-started)
* [Installation](#installation)
* [Submitting the workflow](#submit)
* [Community and Documentation](#community)
* [Authors](#authors)
* [Questions, bugs, and suggestions](#questions)
* [License](#license)
* [Funding](#funding)

## <a name="getting-started"></a>Getting Started 

To run this application you will need a Developer Cloud Sandbox that can be requested at support (at) terradue.com

A Developer Cloud Sandbox provides Earth Sciences data access services, and helper tools for a user to implement, test and validate a scalable data processing application. It offers a dedicated virtual machine and a Cloud Computing environment.
The virtual machine runs in two different lifecycle modes: Sandbox mode and Cluster mode. 
Used in Sandbox mode (single virtual machine), it supports cluster simulation and user assistance functions in building the distributed application.
Used in Cluster mode (a set of master and slave nodes), it supports the deployment and execution of the application with the power of distributed computing for data processing over large datasets (leveraging the Hadoop Streaming MapReduce technology). 

## <a name="installation"></a>Installation

### Pre-requisites

The requirements of the this application are:

* miniconda
* openjpeg2
* gdal
* sen2cor

To install these packages, run the simple steps below on the Developer Cloud Sandbox shell:

```bash
sudo yum install -y miniconda openjpeg2
sudo conda install -y gdal
sudo conda install -y sen2cor=2.2.1
```

### Using the development version

Install the pre-requisites as instructed above.

Log on the Developer Cloud Sandbox and run these commands in a shell:

```bash
cd
git clone https://github.com/ec-melodies/dcs-bash-sentinel2.git
cd dcs-bash-sentinel2
mvn install
```

### Using the release version

Log on the Developer Cloud Sandbox.

Install the package by running this command in a shell:

```bash
sudo yum -y install dcs-bash-sentinel2
```

> At this stage there are no releases yet

### <a name="submit"></a>Submitting the workflow

To submit the application with its default parameters, run the command below in the Developer Cloud Sandbox shell:

```bash
ciop-run
```
Or invoke the Web Processing Service via the Sandbox dashboard.

### <a name="community"></a>Community and Documentation

To learn more and find information go to 

* [Developer Cloud Sandbox](http://docs.terradue.com/developer-sandbox/)  

### <a name="authors"></a>Authors (alphabetically)

* Cesare Rossi

### <a name="questions"></a>Questions, bugs, and suggestions

Please file any bugs or questions as [issues](https://github.com/ec-melodies/dcs-bash-sentinel2/issues) or send in a pull request if you corrected any.

### <a name="license"></a>License

Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0

### <a name="funding"></a>Funding

This work has received funding from the European Union’s Seventh Programme for research, technological development and demonstration under grant agreement number 603525.
